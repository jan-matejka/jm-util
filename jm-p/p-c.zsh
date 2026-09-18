#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

set -eu

PODMAN=${JM_P_PODMAN:-podman}

case $SELF in
  p-c|pc-c|pc-container) subcmd=container ;;
  p-n|pc-n|pc-network) subcmd=network ;;
  *) fatal "unrecognized alias" ;;
esac

if [[ ${1:-} == prune ]]; then
  shift
  exec ${PODMAN} $subcmd prune -f "$@"
else
  exec ${PODMAN} $subcmd "$@"
fi
