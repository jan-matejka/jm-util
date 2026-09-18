###
p-c
###

podman container/network shortcuts
###################################

:Manual section: 1
:Date: 2026-09-18
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

  p-c <args>

  p-n <args>

DESCRIPTION
===========

``p-c`` passes ``<args>`` through to ``podman container``, and ``p-n`` to
``podman network`` -- except when the first of ``<args>`` is ``prune``,
where ``-f`` is inserted right after it, i.e. ``p-c prune`` runs
``podman container prune -f`` and ``p-n prune`` runs
``podman network prune -f``.

``pc-c``/``pc-container`` are aliases of ``p-c``; ``pc-n``/``pc-network``
are aliases of ``p-n``.

ENVIRONMENT
===========

JM_P_PODMAN
  podman executable to use. Defaults to ``podman``.

.. include:: ../core/common-foot.rst
