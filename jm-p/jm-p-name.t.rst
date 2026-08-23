invalid template::

  $ jm p name foo
  jm-p-name: fatal: nonce placeholder not in template
  [1]

missing podman::

  $ export JM_P_PODMAN=plumbus
  $ jm p name 'foo%s'
  /.*/jm-p-name:21: command not found: plumbus (re)
  [127]

  $ unset JM_P_PODMAN

nominal::

.. podman can not run in a container because even just podman-ps or
   podman-container-exists requires newuidmap.

  $ export JM_P_PODMAN=false
  $ jm p name 'foo%s'
  foo1

nonce exhaustion::

  $ export JM_P_PODMAN=true
  $ jm p name 'foo%s'
  jm-p-name: fatal: nonce exhausted
  [1]
