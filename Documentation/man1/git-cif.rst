git-cif
#######

Commit Files
------------

:Manual section: 1
:Date: 2024-09-14
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

git cif [-aew]

DESCRIPTION
===========

Commit all tracked files with a generated commit message. Each file is committed separately (unless
-a is given) with the file path as commit message.

OPTIONS
=======

-e      Open vim to edit the commit generated message.

-w      Add a "WIP" marker to the commit message.

-a      Commit the files in single commit using longest common path prefix as commit message.

.. include:: ../common-foot.rst
