git-cif
#######

Commit Files
------------

:Manual section: 1
:Date: 2026-09-03
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

git cif [opts]

DESCRIPTION
===========

Commit with a longest common prefix path as commit message.

.. It may be time to do this in an actual programming language.

Todo
^^^^

- determining the fixup commits could be probably be decently automated as
  well. It would also completely eliminate the idea of having
  ``git-fixup --primary-sel-as-committish``.

- --amend mode is sorely needed.
  Maybe not a priority. Muscle memory is adjusting.

  A curious pattern is emerging where I trigger an `Automation`_ to get the
  proper commit subject and then amend the commit with the rest of changes that
  should've been part of the commit.

- git-cif config subcommand.

  - this needs an actually usable toml tool.

- Do we want the ability to commit individual hunks with -d mode?

  - Perhaps we could run some inference on the hunks context to autogenerate CC
    message.

  - Perhaps externally so each project can define its set of heuristics to run.

  - Might even not need heuristics if first few words of each hunk are distinct
    enough.

Automation
^^^^^^^^^^

CC type
  - Is set to "rm" if a single file is being deleted from the repository.

  - Is set to "mv" if a single file is being renamed.

  - Is set to "ft" if a a single file is being added to the repository.

  - An explicit -t option takes precedence over all the automatically
    determined types above.

CC message
  - Is prefixed with "add " if a single file is being added to the repository.

  - Is set to 'old -> new' if a message is not provided explicitly
    (-m) and single file is being renamed.

OPTIONS
=======

-a
  Commit all changes to tracked files. Not just the index.

-w
  Add a "wip:" marker to the commit message.

-m <msg>
  Use the given <msg> as the commit message.

-q
  Suppress commit summary message.

-d
  Commit each file separately. Does not open EDITOR for individual messages by
  default. See `Discrete`_ user story.

-t <type>
  Conventional Commit type.

-*
  Options not recognized are passed through to git-commit

USER STORIES
============

Discrete
^^^^^^^^

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

Settings are read from the ``[tool.jmutil.gitcif]`` table of a
``project.toml`` or ``pyproject.toml`` respectively in the git work tree root.

jmutil.gitcif.lcpp-trim-file-name
  Strip the file name from the lcpp if true. Default: false.

  Trimming the filename is typically desired when
  working with code as the parent directory is typically the appropriate
  context.

  It is typically not desired for documentation or data / content
  focused projects.

  This setting does not apply to files in the git work tree root.

  FIXME: since a repository may contain both code and documentation it is clear
  a more nuanced approach is required for full resolution.

jmutil.gitcif.lcpp-trim-file-ext
  Strip the file extension from the lcpp if true. Default: true.

  If lcpp-trim-file-name is not active, it is typically desired to trim the
  extension because it does not add any valuable context and can typically be
  inferred from the rest of the commit subject.

  FIXME: Perhaps we could also look for files with the same base name but
  different extension to decide automatically if we should keep it or not.

jmutil.gitcif.scope-rewrite
  A list of ``sed`` expressions, applied in order to the lcpp path before
  it becomes the commit subject.

  Example, stripping a ``src/`` prefix from the lcpp::

    [tool.jmutil.gitcif]
    scope-rewrite = ["s#^src/##"]

  Applied after the lcpp is computed but before
  ``jmutil.gitcif.lcpp-trim-file-name`` / ``jmutil.gitcif.lcpp-trim-file-ext``,
  so a rule that changes whether the result still refers to an actual file
  on disk affects whether those two settings trigger.

EXIT STATUS
===========

The exit status of the underlying git-commit is returned for non -d operation.

.. include:: ../core/common-foot.rst
