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

git cif [-1ew]

DESCRIPTION
===========

Commit all tracked files with a generated commit message. Each file is
committed separately (unless -1 is given) with the file path as commit message.

OPTIONS
=======

-a      Commit all changes to tracked files. Not just the index.

-e      Open vim to edit the commit generated message.

-w      Add a "WIP" marker to the commit message.

-1      Commit the files in single commit using longest common path prefix as
        commit message.

        Defaults to off but is implied by not using -a.

        Practically meaning -1 is implied if you have staged changes because:
        1. If you have staged, you probably don't want to use -a.
        2. If you do use -a you probably don't have staged changes or don't
           care about them (consistent with git-commit -a).

        This allows to commit index with partially staged files.

.. include:: common-foot.rst
