setup::

  $ cat >$TMPDIR/podman <<'EOF'
  > #!/bin/zsh
  > printf "%s\n" $0 $@
  > EOF
  $ chmod +x $TMPDIR/podman
  $ export JM_P_PODMAN=$TMPDIR/podman

p-c passes through to podman container when the next arg isn't prune::

  $ p-c ls
  */podman (glob)
  container
  ls

p-c prune expands to podman container prune -f::

  $ p-c prune
  */podman (glob)
  container
  prune
  -f

p-n passes through to podman network when the next arg isn't prune::

  $ p-n ls --format json
  */podman (glob)
  network
  ls
  --format
  json

p-n prune expands to podman network prune -f::

  $ p-n prune
  */podman (glob)
  network
  prune
  -f

pc-c and pc-container are aliases of p-c::

  $ pc-c prune
  */podman (glob)
  container
  prune
  -f

  $ pc-container ls
  */podman (glob)
  container
  ls

pc-n and pc-network are aliases of p-n::

  $ pc-n prune
  */podman (glob)
  network
  prune
  -f

  $ pc-network ls
  */podman (glob)
  network
  ls
