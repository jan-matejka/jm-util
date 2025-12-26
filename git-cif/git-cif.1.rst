git-cif
#######

Commit Files
------------

:Manual section: 1
:Date: 2025-07-29
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

git cif [-1w] [-m <msg>]

DESCRIPTION
===========

Commit with a longest common prefix path as commit message.

OPTIONS
=======

-a      Commit all changes to tracked files. Not just the index.

-w      Add a "WIP" marker to the commit message.

-m      Use the given <msg> as the commit message.

-q      Suppress commit summary message.

-d      Commit each file separately.

.. include:: ../core/common-foot.rst
