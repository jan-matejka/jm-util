#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

set -eu

: ${JM_CLAUDE_IMAGE:=ghcr.io/jan-matejka/claude:latest}
: ${JM_CLAUDE_CONFIG_HOME:=${JM_CONFIG_HOME}/claude/conf}

declare -A paargs
declare -a pargs
zparseopts -K -D -a pargs -A paargs p -primary -no-workdir a: -account:

o_primary=false
o_account=default

(( ${${(k)paargs}[(I)-a]} )) && o_account=${paargs[-a]}
(( ${${(k)paargs}[(I)--account]} )) && o_account=${paargs[--account]}
(( ${pargs[(I)-p]} )) && o_primary=true
(( ${pargs[(I)--primary]} )) && o_primary=true
{ (( ${pargs[(I)--no-workdir]} )) || $o_primary } && o_workdir=false || o_workdir=true

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

  instance_name=${project}_${branch}
  instance_fs=p/${project}/${branch}
else
  instance_name=no-workdir
  instance_fs=no-workdir
fi

: ${JM_CLAUDE_DATA_HOME:=${JM_DATA_HOME}/claude}
: ${JM_CLAUDE_DATA_PROJECT_BRANCH_HOME:=${JM_CLAUDE_DATA_HOME}/${instance_fs}}
: ${JM_CLAUDE_DATA_PRIMARY_HOME:=${JM_CLAUDE_DATA_HOME}/primary/$o_account}
: ${JM_CLAUDE_CONFIG_KNOWN_HOSTS:=${JM_CONFIG_HOME}/claude/known_hosts}

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
)

if $o_workdir; then
  args+=(
    # volumes - app
    -v ./:/src/${TAG}
    -v ${main}:/src/$(basename ${main}):ro
  )
fi

args+=(
  # volumes runtime for podman
  -v jm-claude-local:/home/user/.local
  -v jm-claude-config:/home/user/.config
  # volumes - config
  -v ${JM_CLAUDE_CONFIG_HOME}:/home/user/.config/claude
)

if $o_primary ; then
  args+=(
    -v ${JM_CLAUDE_DATA_PRIMARY_HOME}:/home/user/.local/share/claude
  )
else
  args+=(
    -v ${JM_CLAUDE_DATA_PROJECT_BRANCH_HOME}:/home/user/.local/share/claude
    -v ${JM_CLAUDE_DATA_PRIMARY_HOME}/settings.json:/home/user/.local/share/claude/settings.json
    -v ${JM_CLAUDE_DATA_PRIMARY_HOME}/.credentials.json:/home/user/.local/share/claude/.credentials.json
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

mkdir -p --mode=0750 ${JM_CLAUDE_DATA_PROJECT_BRANCH_HOME} ${JM_CLAUDE_CONFIG_HOME}

podman run $args $@
