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
declare -a pargs
zparseopts -K -D -a pargs -A paargs $opts

o_primary=false
o_account=default
o_instance=
o_exec=false

function _mkdir() {
  mkdir --mode=0750 -p $@
}

{ (( ${pargs[(I)-e]} )) || (( ${pargs[(I)--exec]} )) } && o_exec=true
(( ${${(k)paargs}[(I)-a]} )) && o_account=${paargs[-a]}
(( ${${(k)paargs}[(I)--account]} )) && o_account=${paargs[--account]}
(( ${${(k)paargs}[(I)-i]} )) && o_instance=${paargs[-i]}
(( ${${(k)paargs}[(I)--instance]} )) && o_instance=${paargs[--instance]}
(( ${pargs[(I)-p]} )) && o_primary=true
(( ${pargs[(I)--primary]} )) && o_primary=true
{ [[ -n ${o_instance} ]] || $o_primary } && o_workdir=false || o_workdir=true

if $o_workdir; then
  root=$(git rev-parse --show-toplevel)
  dotgit=$root/.git
  [[ -f $dotgit ]] || fatal "not a worktree"

  main=$(grep '^gitdir: ' $dotgit | head -n1 | sed 's#^gitdir: ../\(.*\)/.git/.*$#../\1#' || true)
  [[ -n $main ]] || fatal "failed to read gitdir"

  branch=$(git branch --show-current)

  # get project name from docker-compose
  # run docker-compose directly because podman-compose requires working uidmap.
  project=$(docker-compose config --format=json | jq -Mr .name || true)
  if [[ -z $project ]]; then
    # fall back to parent dir name
    project=$(basename $(realpath $main/..))
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

: ${JM_CLAUDE_CONFIG_SKILLS:=${JM_CLAUDE_CONFIG_HOME}/skills}
: ${JM_CLAUDE_DATA_HOME:=${JM_DATA_HOME}/claude}

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
  args+=(
    # volumes - app
    -v ./:/src/${TAG}
    -v ${main}:/src/$(basename ${main}):ro
  )
else
  _mkdir ${JM_CLAUDE_DATA_INSTANCE_SRC}
  args+=(
    -v ${JM_CLAUDE_DATA_INSTANCE_SRC}:/src
  )
fi

args+=(
  # volumes runtime for podman
  -v jm-claude-local:/home/user/.local
  -v jm-claude-config:/home/user/.config
  # volumes - config
  -v ${JM_CLAUDE_CONFIG_HOME}:/home/user/.config/claude
)
_mkdir ${JM_CLAUDE_CONFIG_HOME}

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
