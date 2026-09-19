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

  - Running multiple instances against the same worktree and branch is
    unsupported and uncoordinated.

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

- Confirm claude's auto-created memory dir persists (rides the
  ``~/.claude`` -> mounted data-home symlink today; not verified
  elsewhere).

- Might requires relative .git link files. (>=git-2.48).
  Unclear if is still true in current implementation. Probably not.

- ``instance_name``/``instance_fs`` are now keyed on the repository's
  absolute ``COMMON_DIR`` (``jm-claude-design(7)``, Instance keying) --
  collision-free regardless of directory naming, but the resulting names
  are long and unreadable, and give no hint of which project/worktree
  they belong to at a glance. A topology-aware naming strategy (one that
  picks a short, readable name while staying aware of what actually
  disambiguates repositories/worktrees on this host, instead of guessing
  from a directory or compose-project name) would be preferable, but
  isn't designed yet.

  Also unresolved from before this: whether keying should really be
  worktree-based at all, or should go back to branch-based -- separate
  question from the naming-string format above.

- Container entrypoint should refuse to start if the image's build info
  (read from an env var baked in at build time) is older than a week,
  unless ``-f``/``--force`` is given -- a staleness guard against running
  claude in a container built against a now-outdated base image/toolchain
  without noticing. Not designed or implemented yet.

- Reconsider whether the container-first model (claude runs inside the
  hardened container; the host only ever bind-mounts/pushes/pulls) is
  still the right shape, versus a harness (possibly MCP-based) on the
  host that connects to and drives a containerized claude instance. The
  container-first model is what gives claude no path out of the sandbox
  by construction; a driving harness would need some privileged channel
  back into the container, which is the opposite boundary, so this isn't
  a drop-in swap. If the actual complaint turns out to be about
  observability (watching progress, a UI) rather than the sandboxing
  itself, a read-only status/log-reading MCP server (or similar) that
  doesn't drive the container might get the wanted benefit without
  touching the security model. Not explored yet.

SEE ALSO
========

``jm-claude(1)``, ``jm-claude-design(7)``

.. include:: ../core/common-license.rst
