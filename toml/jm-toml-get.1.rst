jm-toml-get
###########

Read a key out of the project's TOML config
--------------------------------------------

:Manual section: 1
:Date: 2026-09-08
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

jm toml-get <key> [<default>]

DESCRIPTION
===========

Reads ``<key>`` -- a dotted TOML path, e.g. ``tool.jmutil.claude.account``
-- from ``<repo-root>/project.toml`` or ``<repo-root>/pyproject.toml``,
whichever exists and has it first. ``<repo-root>`` is the current git
repository's toplevel.

A trailing ``[]`` on ``<key>`` reads an array, one element printed per
output line.

Prints ``<key>``'s value and exits 0 if present. Otherwise prints
``<default>``, if one was given, and exits 1.

If neither ``yq-go`` nor ``yq`` is available, warns and behaves as if
``<key>`` were absent.

OPTIONS
=======

None

ENVIRONMENT
===========

JM_UTIL_YQ
  ``yq-go`` or ``yq``, whichever is used to read TOML. Auto-detected
  (``yq-go`` preferred) if unset.

.. include:: ../core/common-foot.rst
