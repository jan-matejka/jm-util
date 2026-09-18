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

[[ ${1:-} == prune ]] && set -- prune -f "${@:2}"
exec ${PODMAN} $subcmd "$@"
