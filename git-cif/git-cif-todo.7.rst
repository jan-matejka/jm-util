git-cif todo
############

git-cif todo
------------

:Manual section: 1
:Date: 2026-09-03
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

TODO
====

- determining the fixup commits could probably be decently automated as
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

- ft might be the default CC type. This might be very project dependent tho.

- Subject / Path compaction

  Multiple use cases:

  - LCPP use for subject

  - mv path gen

  Compaction needs to be invertible.

- Commit compaction / squash

  - Some commits can clearly be squashed automatically, like td CC types with
    no message.

- -a should be the default mode in the absence of other options or partially
  staged index perchance?

- needs a flag for emphasis / breaking change (! marker).

  - and it shall be formatted at the end of the subject line.

    - probably. It just makes sense. But there may be some value in having it at
      the end of the scope when eyeballing it. No, I don't think so. idk tho.

- Use case - wip workflow, refactor & update sibling subsystems

.. include:: ../core/common-license.rst
