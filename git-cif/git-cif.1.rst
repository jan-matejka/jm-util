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

CONFIGURATION
=============

git config
----------

jmutil.gitcif.lcpp-trim-file-name
  Strip the file name from the lcpp if true. Default: false.

  Valid values: arbitrary shell command. Typically "true" / "false".

  Trimming the filename is typically desired when
  working with code as the parent directory is typically the appropriate
  context.

  It is typically not desired for documentation or data / content
  focused projects.

  This setting does not apply to files in the git work tree root.

  FIXME: since a repository may contain both code and documentation it is clear
  a more nuanced approach is required for full resolution.

  FIXME: It should also be possible to read this setting from a file commited
  to the repository.

  FIXME: doesn't apply to discrete commits and it is unclear if it should.

jmutil.gitcif.lcpp-trim-file-ext
  Strip the file extension from the lcpp if true. Default: true.

  Valid values: arbitrary shell command. Typically "true" / "false".

  If lcpp-trim-file-name is not active, it is typically desired to trim the
  extension because it does not add any valuable context and can typically be
  inferred from the rest of the commit subject.

  FIXME: It should also be possible to read this setting from a file commited
  to the repository.

  FIXME: doesn't apply to discrete commits and it is unclear if it should.

  FIXME: Perhaps we could also look for files with the same base name but
  different extension to decide automatically if we should keep it or not.

jmutil.gitcif.scope-rewrite
  A multi-valued list of ``sed`` expressions, applied in order to
  the lcpp path before it becomes the commit subject.

  Example, stripping a ``src/`` prefix from the lcpp::

    git config set --local --append jmutil.gitcif.scope-rewrite 's#^src/##'

  Applied after the lcpp is computed but before
  ``jmutil.gitcif.lcpp-trim-file-name`` / ``jmutil.gitcif.lcpp-trim-file-ext``,
  so a rule that changes whether the result still refers to an actual file
  on disk affects whether those two settings trigger.

  FIXME: Should apply to discrete commits.

.. include:: ../core/common-foot.rst
