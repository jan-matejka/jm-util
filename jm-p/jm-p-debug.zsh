#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

set -eu

PODMAN=${JM_P_PODMAN:-podman}
NAME=${JM_P_NAME:-jm-p-name}

container_id=${1:?container_id not set}
shift

container_name=$(${NAME} "jm_debug-$container_id-%s")

args=(
  -it
  --rm
  --name $container_name
  --pid=container:$container_id
  --network=container:$container_id
  --userns=container:$container_id
  --cap-add=SYS_PTRACE
  # SYS_PTRACE is needed to access /proc/1/root
  docker.io/nicolaka/netshoot
  zsh
)

exec ${PODMAN} run $args
