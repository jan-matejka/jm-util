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

- Need a better mechanism to push/pull to/from upstream and claude.

  - Running multiple instance on multiple worktrees is fine.

  - Running multiple instances against the same worktree and branch isn't
    guarded: the second one just collides -- on the podman container name,
    or on the ``claude/<branch>`` switch if launched close enough together.
    Not unsafe, just unsupported (``jm-claude(1)``, Known limitations).
    Might be worth an explicit check (or lock) with a clearer error instead
    of relying on the incidental podman name collision. Not implemented.

  - jm-claude now switches the current branch into the ``claude/`` namespace
    automatically (creating ``claude/<branch>``, or fast-forwarding onto an
    existing one), so integrating back into the original branch for
    upstreaming is still a manual step.

- The automatic branch tracking is a bit sus but unlikely a footgun. At worst
  you just push into a local repo. The hard reset is somewhat unsafe tho.

  - Possible mitigation for the live-sync ``reset --hard`` hazard
    (``jm-claude-design(7)``, Known hazards): ``git stash`` the target work
    tree before resetting it, instead of discarding uncommitted changes
    outright. Not implemented.

- Changes to skills on the host should be visible to the running containers.

- jm-claude should probably be able to also create a new worktree and launch
  a new claude instance in that worktree for state isolation.

  Could also form a basis for more automation.

- option to wipe session data

- Might requires relative .git link files. (>=git-2.48).
  Unclear if is still true in current implementation. Probably not.

SEE ALSO
========

``jm-claude(1)``, ``jm-claude-design(7)``

.. include:: ../core/common-license.rst
