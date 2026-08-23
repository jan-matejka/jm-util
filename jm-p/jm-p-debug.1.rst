##########
jm-p-debug
##########

Run debug container
###################

:Manual section: 1
:Date: 2026-08-22
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

  jm p debug <container>

DESCRIPTION
===========

Run a debug container inside <container>'s namespaces.

Why? podman-debug corresponding to docker-debug does not exist.

You can access <container>'s root via /proc/1/root and chroot into it as well.

.. include:: ../core/common-foot.rst
