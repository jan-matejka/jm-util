#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

set -eu

: ${JM_CLAUDE_IMAGE:=ghcr.io/jan-matejka/claude:latest}
: ${JM_CLAUDE_CONFIG_HOME:=${JM_CONFIG_HOME}/claude/conf}

opts=(
  p -primary
  a: -account:
  i: -instance:
  e -exec
)
declare -A paargs
zparseopts -K -D -A paargs $opts

o_primary=false
o_instance=
o_exec=false
o_account=default

function _mkdir() {
  mkdir --mode=0750 -p $@
}

has_opt -e && o_exec=true
has_opt --exec && o_exec=true
has_opt -a && o_account=${paargs[-a]}
has_opt --account && o_account=${paargs[--account]}
has_opt -i && o_instance=${paargs[-i]}
has_opt --instance && o_instance=${paargs[--instance]}
has_opt -p && o_primary=true
has_opt --primary && o_primary=true
{ [[ -n ${o_instance} ]] || $o_primary } && o_workdir=false || o_workdir=true

: ${JM_CLAUDE_DATA_HOME:=${JM_DATA_HOME}/claude}

root=$(git rev-parse --show-toplevel 2>/dev/null || true)

if $o_workdir; then
  if ! { has_opt -a || has_opt --account }; then
    o_account=$(jm toml-get tool.jmutil.claude.account $o_account)
  fi
  # Determine project and branch
  # Needed to define base paths
  branch=$(git branch --show-current)

  # get project name from docker-compose
  # run docker-compose directly because podman-compose requires working uidmap.
  project=$(docker-compose config --format=json | jq -Mr .name || true)
  if [[ -z $project ]]; then
    # fall back to parent dir name
    project=$(basename $(dirname $root))
  fi

  instance_name=p_${project}_${branch}
  instance_fs=p/${project}/${branch}
else
  if [[ -n $o_instance ]]; then
    instance_name=i_${o_instance}
    instance_fs=i/${o_instance}
  elif $o_primary; then
    instance_name=primary
    instance_fs=primary
  else
    fatal "Invalid internal state"
  fi
fi

: ${JM_CLAUDE_CONFIG_HOME_ACCOUNT:=${JM_CLAUDE_CONFIG_HOME}/account/$o_account}
: ${JM_CLAUDE_CONFIG_SKILLS:=${JM_CLAUDE_CONFIG_HOME}/skills}

: ${JM_CLAUDE_DATA_INSTANCE_HOME:=${JM_CLAUDE_DATA_HOME}/home/${instance_fs}}
: ${JM_CLAUDE_DATA_PRIMARY_HOME:=${JM_CLAUDE_DATA_HOME}/primary/$o_account}
: ${JM_CLAUDE_CONFIG_KNOWN_HOSTS:=${JM_CONFIG_HOME}/claude/known_hosts}
: ${JM_CLAUDE_DATA_INSTANCE_SRC:=${JM_CLAUDE_DATA_HOME}/data/${instance_name}}

if $o_exec; then
  podman exec -it jm_claude_$instance_name zsh
  exit $?
fi

args=(
  # standard flags
  -it --rm
  --name jm_claude_${instance_name}
  # user mapping
  --userns="keep-id:uid=$(id -u),gid=$(id -g)"
  # hardening
  --cap-drop=ALL
  --security-opt=no-new-privileges
  --read-only
  # environment
  # Doctor doesnt work in container.
  -e DISABLE_DOCTOR_COMMAND=1
)

if $o_workdir; then
  # Topology resolution
  common_dir=$(realpath $(git rev-parse --git-common-dir))
  work_git_dir=$(realpath $(git rev-parse --git-dir))
  dotgit_is_file=false
  [[ -f $root/.git ]] && dotgit_is_file=true

  # Instance keying
  if [[ $work_git_dir != $common_dir ]]; then
    worktree_name=$(basename $work_git_dir)
  else
    worktree_name=$(basename $root)
  fi
  # Mounts: container-side paths and LOCAL_GITDIR's host path
  ct_common=/run/jm-claude/git-common-ro
  ct_work=$ct_common
  [[ $work_git_dir != $common_dir ]] && ct_work=/run/jm-claude/git-work-ro
  ct_local=/run/jm-claude/git-local
  local_gitdir=${JM_CLAUDE_DATA_HOME}/gitdir/${common_dir}/${worktree_name}
  _mkdir $(dirname $local_gitdir)

  # Container-local git-dir seeding
  if [[ ! -f $local_gitdir/HEAD ]]; then
    git init -q --bare $local_gitdir
    git --git-dir=$local_gitdir config core.bare false
    git --git-dir=$local_gitdir config core.logAllRefUpdates true

    print -r -- "${common_dir}/objects" > $local_gitdir/objects/info/alternates
    cp $work_git_dir/HEAD $local_gitdir/HEAD
    [[ -f $work_git_dir/index ]] && cp $work_git_dir/index $local_gitdir/index
    # cp ``foo/.`` copies correctly into an existing destination, instead of under it
    cp -r $common_dir/refs/. $local_gitdir/refs/
    [[ -f $common_dir/packed-refs ]] && cp $common_dir/packed-refs $local_gitdir/packed-refs
  fi
  git --git-dir=$local_gitdir config core.worktree /src

  # gitlink file for the worktree-topology mount case
  if $dotgit_is_file; then
    gitlink_file=${local_gitdir}.gitlink
    print -r -- "gitdir: ${ct_local}" > $gitlink_file
  fi

  # Container-valid alternates, shadowing the host-valid one written into
  # local_gitdir itself above (Mounts, below) -- same shadow-mount
  # principle as the gitlink file.
  alternates_shadow_file=${local_gitdir}.alternates
  print -r -- "${ct_common}/objects" > $alternates_shadow_file

  # git-remote setup
  remote_name=claude-${worktree_name}
  if git -C $root remote get-url $remote_name >/dev/null 2>&1; then
    git -C $root remote set-url $remote_name $local_gitdir
  else
    git -C $root remote add $remote_name $local_gitdir
  fi
  if [[ $branch == $worktree_name ]]; then
    git -C $root config branch.${branch}.remote $remote_name
    git -C $root config branch.${branch}.merge refs/heads/${branch}
  fi

  args+=(
    # volumes - app
    -v ./:/src
    -v ${common_dir}:${ct_common}:ro
  )
  [[ $ct_work != $ct_common ]] && args+=( -v ${work_git_dir}:${ct_work}:ro )
  if $dotgit_is_file; then
    args+=(
      -v ${local_gitdir}:${ct_local}
      -v ${gitlink_file}:/src/.git:ro
      -v ${alternates_shadow_file}:${ct_local}/objects/info/alternates:ro
    )
  else
    args+=(
      -v ${local_gitdir}:/src/.git
      -v ${alternates_shadow_file}:/src/.git/objects/info/alternates:ro
    )
  fi
else
  _mkdir ${JM_CLAUDE_DATA_INSTANCE_SRC}
  args+=(
    -v ${JM_CLAUDE_DATA_INSTANCE_SRC}:/src
  )
fi

args+=(
  # volumes runtime for podman
  -v jm-claude-local-a-${o_account}:/home/user/.local
  -v jm-claude-config-a-${o_account}:/home/user/.config
  # volumes - config
  -v ${JM_CLAUDE_CONFIG_HOME_ACCOUNT}:/home/user/.config/claude
)
_mkdir ${JM_CLAUDE_CONFIG_HOME_ACCOUNT}

if $o_primary ; then
  args+=(
    -v ${JM_CLAUDE_DATA_PRIMARY_HOME}:/home/user/.local/share/claude
  )
  _mkdir ${JM_CLAUDE_DATA_PRIMARY_HOME}
else
  args+=(
    -v ${JM_CLAUDE_DATA_INSTANCE_HOME}:/home/user/.local/share/claude
    -v ${JM_CLAUDE_DATA_PRIMARY_HOME}/settings.json:/home/user/.local/share/claude/settings.json
    -v ${JM_CLAUDE_DATA_PRIMARY_HOME}/settings.json:/home/user/.local/share/claude/settings.json
    -v ${JM_CLAUDE_DATA_PRIMARY_HOME}/.credentials.json:/home/user/.local/share/claude/.credentials.json
  )
  _mkdir ${JM_CLAUDE_DATA_INSTANCE_HOME} ${JM_CLAUDE_DATA_PRIMARY_HOME}
fi

if test -d ${JM_CLAUDE_CONFIG_SKILLS}; then
  args+=(
    -v ${JM_CLAUDE_CONFIG_SKILLS}:/home/user/.local/share/claude/skills
  )
fi

if test -f ${JM_CLAUDE_CONFIG_HOME_ACCOUNT}/CLAUDE.md; then
  args+=(
    -v ${JM_CLAUDE_CONFIG_HOME_ACCOUNT}/CLAUDE.md:/home/user/.local/share/claude/CLAUDE.md
  )
fi

function add_vm_args {
  local i
  for i in CONTAINER_HOST CONTAINER_SSHKEY CONFIG_KNOWN_HOSTS; do
    local var=JM_CLAUDE_$i
    [[ -n ${(P)var:-} ]] || return 0
  done

  args+=(
    -e CONTAINER_HOST=${JM_CLAUDE_CONTAINER_HOST:?}
    -e CONTAINER_SSHKEY=/home/user/.ssh/id_ed25519
    -v ${JM_CLAUDE_CONFIG_KNOWN_HOSTS}:/home/user/.ssh/known_hosts:ro
    -v ${JM_CLAUDE_CONTAINER_SSHKEY}:/home/user/.ssh/id_ed25519:ro
  )
}

add_vm_args
args+=( ${JM_CLAUDE_IMAGE} )

podman run $args $@
