#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

set -eu

PODMAN=${JM_P_PODMAN:-podman}

typeset -A subcmds=(
  p-c container  pc-c container  pc-container container
  p-n network    pc-n network    pc-network   network
)
subcmd=${subcmds[$SELF]:-}
[[ -n $subcmd ]] || fatal "unrecognized alias"

if [[ ${1:-} == prune ]]; then
  shift
  exec ${PODMAN} $subcmd prune -f "$@"
else
  exec ${PODMAN} $subcmd "$@"
fi
