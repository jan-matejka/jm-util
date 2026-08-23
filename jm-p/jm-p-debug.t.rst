  $ export JM_P_PODMAN=echo
  $ export JM_P_NAME=echo
  $ jm p debug foo
  run -it --rm --name jm_debug-foo-%s --pid=container:foo --network=container:foo --userns=container:foo --cap-add=SYS_PTRACE docker.io/nicolaka/netshoot zsh
