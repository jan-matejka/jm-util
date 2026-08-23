#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

set -eu

PODMAN=${JM_P_PODMAN:-podman}
MAX_ID=${JM_P_NAME_MAX_ID:-100}

template=${1:?template not set}
shift

echo $template | grep -qF '%s' || fatal "nonce placeholder not in template"

i=1
while true; do
  container_name=$(printf $template $i)

  rc=0
  ${PODMAN} container exists $container_name || rc=$?
  (( $rc > 125 )) && exit $rc

  if (( $rc == 0 )); then
    (( i++ ))
  else
    break
  fi

  if (( i > MAX_ID )); then
    fatal "nonce exhausted"
  fi
done

printf "%s\n" $container_name
