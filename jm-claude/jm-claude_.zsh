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
  w -isolated-workdir
)
declare -A paargs
zparseopts -K -D -A paargs $opts

o_primary=false
o_instance=
o_exec=false
o_account=default
o_isolated=false
podman_args=()

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
has_opt -w && o_isolated=true
has_opt --isolated-workdir && o_isolated=true
{ [[ -n ${o_instance} ]] || $o_primary } && o_workdir=false || o_workdir=true
$o_isolated && ! $o_workdir && fatal "-w/--isolated-workdir requires git-context (workdir) mode: drop -p/-i"

: ${JM_CLAUDE_DATA_HOME:=${JM_DATA_HOME}/claude}

root=$(git rev-parse --show-toplevel 2>/dev/null || true)

if $o_workdir; then
  if ! { has_opt -a || has_opt --account }; then
    o_account=$(jm toml-get tool.jmutil.claude.account $o_account)
  fi
  # Extra podman-run args from project.toml/pyproject.toml, appended after
  # every automatically-set flag (see below) so they can override any of
  # them.
  podman_args=( ${(f)"$(jm toml-get 'tool.jmutil.claude.podman_args[]')"} ) || podman_args=()

  # Topology resolution
  common_dir=$(realpath $(git rev-parse --git-common-dir))
  work_git_dir=$(realpath $(git rev-parse --git-dir))
  dotgit_is_file=false
  [[ -f $root/.git ]] && dotgit_is_file=true

  # Instance keying: worktree-keyed on common_dir/worktree_name, same as
  # LOCAL_GITDIR (jm-claude-design(7), Instance keying) -- one instance
  # per worktree, independent of whichever branch happens to be checked
  # out there. common_dir is the repository's unique, absolute
  # git-common-dir, so -- unlike a project-name guess (e.g. a
  # docker-compose project name, or a parent-directory basename) -- this
  # can't collide across unrelated repositories.
  if [[ $work_git_dir != $common_dir ]]; then
    worktree_name=$(basename $work_git_dir)
  else
    worktree_name=$(basename $root)
  fi
  instance_name=p${common_dir//\//_}_${worktree_name}
  instance_fs=p/${common_dir}/${worktree_name}

  # Determine branch
  branch=$(git branch --show-current)
  [[ -n $branch ]] || fatal "HEAD is not a branch"

  # Work in the claude/ namespace, so the branch the user upstreams from
  # is never the one claude commits to directly.
  if [[ $branch != claude/* ]]; then
    orig_branch=$branch
    branch=claude/$branch
    if git -C $root show-ref --verify --quiet refs/heads/$branch; then
      git -C $root checkout $branch
      git -C $root merge --ff-only $orig_branch
    else
      git -C $root checkout -b $branch
    fi
  fi
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
  # claude (PID 1 in the container) never reaps children, so any orphaned
  # subprocess -- git-hook-spawned or otherwise -- would sit as a zombie
  # for the container's whole lifetime. --init gives it a real PID 1
  # (tini) that does.
  --init
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
  # Mounts: container-side paths and LOCAL_GITDIR's host path
  ct_common=/run/jm-claude/git-common-ro
  ct_work=$ct_common
  [[ $work_git_dir != $common_dir ]] && ct_work=/run/jm-claude/git-work-ro
  ct_local=/run/jm-claude/git-local
  ct_shared=/run/jm-claude/git-shared
  local_gitdir=${JM_CLAUDE_DATA_HOME}/gitdir/${common_dir}/${worktree_name}
  # One shared bare repo per common_dir (not per worktree): every
  # worktree's container pushes its branch here, so the host only
  # needs a single "claude" remote instead of one per worktree.
  shared_gitdir=${JM_CLAUDE_DATA_HOME}/gitdir/${common_dir}/shared
  _mkdir $(dirname $local_gitdir)
  [[ -d $shared_gitdir ]] || git init -q --bare $shared_gitdir

  # -w/--isolated-workdir: /src is backed by a container-owned checkout
  # instead of the host's live work tree, keyed the same way as
  # local_gitdir so it persists across runs. It's always a plain
  # directory jm-claude fully owns, so the gitlink-shadow dance below
  # (needed only to match an existing host $ROOT/.git's file-vs-dir
  # type) never applies to it.
  if $o_isolated; then
    isolated_src=${JM_CLAUDE_DATA_HOME}/src/${common_dir}/${worktree_name}
    dotgit_is_file=false
  fi

  # (Re)install the post-receive hook every run so it always matches
  # this script's version. On a push it mirrors the branch into
  # whichever worktree owns it -- live, via reset --hard on the real
  # (bind-mounted) work tree -- so a push landing here (from the host,
  # or from a `git push` run inside another exec'd shell in the same
  # container) shows up immediately without restarting the container.
  cat > $shared_gitdir/hooks/post-receive <<'EOF'
#!/bin/sh
# A push from a claude container's own worktree is always already
# reflected there (you can't push a commit you haven't got), so it
# needs no reset -- and indeed there's nothing here to derive it from:
# only the fixed /run/jm-claude/git-{local,shared,...} mounts exist
# inside a container, not a path named after the branch, so the
# sibling lookup below simply finds nothing and no-ops.
while read -r oldrev newrev refname; do
  case $refname in
    refs/heads/*) ;;
    *) continue ;;
  esac
  branch=${refname#refs/heads/}

  # The worktree lives next to us, keyed by branch name.
  git_dir=../$branch
  [ -f "$git_dir.worktree" ] || continue
  work_tree=$(cat "$git_dir.worktree")

  [ "$(git --git-dir=$git_dir rev-parse -q --verify HEAD)" = "$newrev" ] && continue
  git --git-dir=$git_dir --work-tree=$work_tree reset --hard $newrev
done
EOF
  chmod +x $shared_gitdir/hooks/post-receive

  # Container-local git-dir seeding
  if [[ ! -f $local_gitdir/HEAD ]]; then
    git init -q --bare $local_gitdir
    git --git-dir=$local_gitdir config core.bare false
    git --git-dir=$local_gitdir config core.logAllRefUpdates true

    # Carry over the host's committer identity -- without this, a
    # commit made in the container fails with "Author identity
    # unknown" since local_gitdir starts with no config of its own.
    # Fall back to the current user / user@hostname if the host repo
    # has none configured either.
    : ${name:=$(id -un)}
    : ${email:=$(id -un)@$(hostname)}
    name=$(git -C $root config get --default $name user.name)
    email=$(git -C $root config get --default $email user.email)
    git --git-dir=$local_gitdir config user.name $name
    git --git-dir=$local_gitdir config user.email $email

    # Also alternate to the shared repo's objects: the post-receive
    # hook resets this gitdir straight to whatever was just pushed
    # there, which may only exist in the shared repo's object store.
    print -l -- "${common_dir}/objects" "${shared_gitdir}/objects" \
      > $local_gitdir/objects/info/alternates
    cp $work_git_dir/HEAD $local_gitdir/HEAD
    [[ -f $work_git_dir/index ]] && cp $work_git_dir/index $local_gitdir/index

    # Seed only the ref HEAD resolves through, not the whole refs tree
    # -- avoids leaking every branch/tag/remote-tracking ref from the
    # host repo into the container-local gitdir.
    if [[ -n $branch && -f $common_dir/refs/heads/$branch ]]; then
      install -D $common_dir/refs/heads/$branch $local_gitdir/refs/heads/$branch
    fi
  fi

  # -w/--isolated-workdir: materialize the container-owned checkout the
  # first time it's needed. Only committed content -- the branch tip
  # local_gitdir was just seeded to above -- ever lands here, never the
  # host's dirty/staged state, so the isolation boundary is unambiguous.
  # Persists across runs (not re-seeded once it exists), same as
  # local_gitdir itself.
  if $o_isolated && [[ ! -d $isolated_src ]]; then
    _mkdir $isolated_src
    git --git-dir=$local_gitdir --work-tree=$isolated_src checkout -q -f $branch
  fi

  git --git-dir=$local_gitdir config core.worktree /src

  # Remote the container pushes to (claude itself, or a user exec'd
  # into the container running git push by hand) -- points at the
  # shared repo's container-side mount, so it only ever gets used from
  # inside the container.
  if git --git-dir=$local_gitdir remote get-url claude >/dev/null 2>&1; then
    git --git-dir=$local_gitdir remote set-url claude $ct_shared
  else
    git --git-dir=$local_gitdir remote add claude $ct_shared
  fi
  # Track it, so a plain `git push`/`git pull` inside the container
  # (by claude, or a user exec'd in) targets it without arguments.
  git --git-dir=$local_gitdir config branch.${branch}.remote claude
  git --git-dir=$local_gitdir config branch.${branch}.merge refs/heads/${branch}

  # Host-valid work tree path, read by the shared repo's post-receive
  # hook when it runs on the host (it can't derive this from
  # local_gitdir's own core.worktree, which is set to the
  # container-valid /src above). Isolated mode points this at the
  # container-owned checkout instead of the host's own work tree, so a
  # push still live-syncs -- just onto isolated_src, never onto $root.
  if $o_isolated; then
    print -r -- "$isolated_src" > ${local_gitdir}.worktree
  else
    print -r -- "$root" > ${local_gitdir}.worktree
  fi

  # gitlink file for the worktree-topology mount case
  if $dotgit_is_file; then
    gitlink_file=${local_gitdir}.gitlink
    print -r -- "gitdir: ${ct_local}" > $gitlink_file
  fi

  # Container-valid alternates, shadowing the host-valid one written into
  # local_gitdir itself above (Mounts, below) -- same shadow-mount
  # principle as the gitlink file.
  alternates_shadow_file=${local_gitdir}.alternates
  print -l -- "${ct_common}/objects" "${ct_shared}/objects" > $alternates_shadow_file

  # git-remote setup: one shared remote for every branch/worktree of
  # this common_dir, backed by the shared bare repo the container(s)
  # push into.
  remote_name=claude
  if git -C $root remote get-url $remote_name >/dev/null 2>&1; then
    git -C $root remote set-url $remote_name $shared_gitdir
  else
    git -C $root remote add $remote_name $shared_gitdir
  fi
  git -C $root config branch.${branch}.remote $remote_name
  git -C $root config branch.${branch}.merge refs/heads/${branch}

  src_mount=./
  $o_isolated && src_mount=$isolated_src
  args+=(
    # volumes - app
    -v ${src_mount}:/src
    -v ${common_dir}:${ct_common}:ro
    -v ${shared_gitdir}:${ct_shared}
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
args+=( $podman_args )
args+=( ${JM_CLAUDE_IMAGE} )

podman run $args $@

