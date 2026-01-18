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

-d      Commit each file separately. Does not open EDITOR for individual
        messages by default. See `Discrete`_ user story.

USER STORIES
============

Discrete
--------

When you work e.g. on a feature and pre-requisite refactoring at the same time.
It is often the case that each of the refactoring and the feature changes code
at distinct files.

If you like to commit often, this gets annoying quickly as you need to either
do ``commit --fixup`` or ``commit -m`` for each iteration.

Another option is to just not to make a distinctive commits for each final
commit, squash everything, reset and do new clean commits. This has the issue
that it is easy to get it mixed up with other changes that should be its own
final commit.

For this use case, there is ``$ git cif -ad`` to commit each file separately
with the file name in commit subject. This way it is easy to review the changes
individually (if you need to go back to something during development) and
squash the commits by their file or file system scope.

.. include:: ../core/common-foot.rst
