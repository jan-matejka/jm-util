jm-container-env-setup
######################

set up common container env
---------------------------

:Manual section: 1
:Date: 2026-08-22
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

jm container-env-setup <command> [<args>]

DESCRIPTION
===========

Set up common container environment and exec <command> <args>.

The setup:

1. If we are in a worktree, make sure .git gitdir is relative path [1]_.

2. Exports TAG set to latest if current branch is master or main. Otherwise
   exports TAG=<branch-name>.

.. [1] There's a feature for relative worktrees in git 2.48. Unfortunately,
   Debian Trixie is on git 2.47.

.. include:: common-foot.rst
