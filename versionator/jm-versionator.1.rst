jm-versionator
##############

Generate version from git
-------------------------

:Manual section: 1
:Date: 2026-06-27
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

jm versionator <opts> -d
jm versionator <opts> <version>

opts := [-x] [-v] [-q] [--dch] [--output-shell]

DESCRIPTION
===========

- Detect a debian compatible version string from HEAD.
- Write it into the source if --output-shell given.
- Update/add debian/changelog entry if --dch given.
- Commit and tag the debian/changelog if --dch given and -d not given.
  Note in this case the version must be passed in argv as this is considered
  release version which is impossible to detect.

Generate a debian compatible version string from a git working tree.

There are 2 distinct workflows.

1. Dev workflow.

   1. jm versionator -d --dch --output-shell foo.sh

   2. debuild ...

   3. Test & repeat

2. Release workflow.

   1. jm versionator --dch --output-shell foo.sh <version>

OPTIONS
=======

-d      Dev release.

-v      Verbose.

-q      Print just the version.

--dch   Use debian/changelog.

        1. Read the last version from it to reset the build counter if base
        version is greater.

        2. Update or create new a entry with the new version.

--output-shell <path>

        Write a shell scripting printing the new version into <path>

.. include:: ../core/common-foot.rst
