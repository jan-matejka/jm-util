gytr-cl
#######

Clone Into An Org/Repo Layout
-----------------------------

:Manual section: 1
:Date: 2026-09-07
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

gytr-cl <url> [<dir>]

DESCRIPTION
===========

Clones ``<url>`` into a separate git-dir + worktree layout, so additional
branches can later be checked out as their own sibling worktrees (``git
worktree add``) next to it.

Given a URL whose path is ``<org>/<repo>`` the result is::

  <dir>/<org>/<repo>/<repo>.git -- the actual git-dir (--separate-git-dir)
  <dir>/<org>/<repo>/<branch>   -- a worktree for the remote's default branch

``<branch>`` is whatever the remote's ``HEAD`` symref points at.

ARGUMENTS
=========

<url>
  Either an ``http://`` / ``https://`` URL, or an SCP-like
  ``host:org/repo.git`` address.

  In all cases the path portion must be exactly ``<org>/<repo>``.

  - A URL with more or fewer path segments is rejected.
    FIXME: This is a defensive design decision to be amended in the future.

  ``http://`` is accepted with a warning.

<dir>
  - Directory to clone into.
  - Relative to CWD.
  - Defaults to ${GIT_ORG_HOME:-~/git}

ENVIRONMENT
===========

GIT_ORG_HOME
  Default value for ``<dir>`` when it is not given explicitly.

EXIT STATUS
===========

Fails with a diagnostic if ``<url>`` doesn't match one of the accepted
forms, or if its path isn't exactly ``<org>/<repo>``. Otherwise, the exit
status of the underlying ``git ls-remote`` or ``git clone`` is returned,
whichever fails first.

.. include:: ../core/common-foot.rst
