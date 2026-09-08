##############
jm-claude-todo
##############

jm-claude TODO
##############

:Manual section: 7
:Date: 2026-09-08
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual
:Status: Rather disorganized set of notes than anything else

TODO
====

- It is also becoming clear I will need to run multiple wip branches.
  Too easy with worktrees but the design would likely involve wip/main and then
  wip/1, wip/2, ... . wip/main being for integrating passing changes.
  Which might get hairy.

- Claude Code makes a distinction between the interactive session (the default
  prompt upon starting claude), and background agents (other tasks started via
  the left-arrow prompt for new session).

  When in the background agent, it automatically tries to use EnterWorktree to
  prevent data races.

  This can be prevented with ``settings.json`` entry::

    "permissions": {"deny": ["EnterWorktree"]}

  Which is useful for claude to not go into rabbit holes on why he can not
  create worktrees.

  But that seems to hard-block the agent from writing (even though there is no
  security guarantee). It can be unblocked with::

    "worktree": {"bgIsolation": "none"},

  But then it is on you not to cause data races.

- Changes to skills on the host should be visible to the running containers.

- jm-claude should probably be able to also create a new worktree and launch
  a new claude instance in that worktree for state isolation.

  Could also form a basis for more automation.

- option to wipe session data

- Possible mitigation for the branch-switch hazard
  (``jm-claude-design(7)``, Known hazards): chmod ``WORK_GIT_DIR``
  read-only for the container's lifetime -- blocks local writes, checkout
  included, at the index-lock step, cleanly. Not implemented.

- Might requires relative .git link files. (>=git-2.48).
  Unclear if is still true in current implementation.

SEE ALSO
========

``jm-claude(1)``, ``jm-claude-design(7)``

.. include:: ../core/common-license.rst
