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

  Resolved (was previously unresolved here): keying should be
  branch-based, not worktree-based -- separate from the naming-string
  format above, which is still open. Worktree-keying was only ever
  correct because ``/src`` was a live bind-mount of one specific
  worktree's on-disk files, so the instance had to be tied to whichever
  worktree it was mounted from. Once that live-mount requirement is gone
  (``-w``/``--isolated-workdir`` and beyond), there's no structural
  reason left to tie an instance to a worktree at all -- a branch name is
  sufficient, and it's what actually lets N agents run concurrently
  without needing N host worktrees. Not yet implemented: today's code
  still keys on ``worktree_name``, not branch.

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
  a drop-in swap.

  Two stated pain points so far:

  - Git repository management -- the ``LOCAL_GITDIR``
    seeding/shadowing/live-sync machinery (``jm-claude-design(7)``) is
    nearly all of the current design's complexity; the container
    hardening flags themselves are simple and not the issue. Note that
    ``-w``/``--isolated-workdir`` does *not* touch any of that machinery
    -- it only changes what backs ``/src``, so it's not evidence either
    way on whether an MCP-mediated file/git protocol would actually be
    simpler to manage than the current mount/shadow approach.

  - Letting claude run containers of its own, safely. Already flagged as
    unfinished in ``jm-claude(1)`` (``SAFETY``, Motivation: "it is
    essential for it to be able to run containers itself, safely (sus,
    WIP)") and partially addressed today by the Remote VM mechanism
    (``JM_CLAUDE_CONTAINER_HOST``/``CONTAINER_SSHKEY``/etc. --
    ``jm-claude(1)``, ENVIRONMENT and DEPENDENCIES). See the next TODO
    item below for the current best fix direction -- it turns out to be
    largely orthogonal to whether a driving harness exists at all.

  Deliberately parked, not spec'd: revisit once ``-w`` has seen enough
  real use to know whether the remaining git-dir machinery is still the
  pain point once the host-work-tree-sharing hazard it addresses is gone,
  or whether it's fine as-is. More pain points may still surface before
  this is worth spec'ing.

- Claude's containers must never be able to start **sibling** containers
  (i.e. anything reachable via a shared podman/docker socket, including
  today's Remote-VM mechanism above): a shared daemon socket has no
  confinement relationship between what's holding the socket and what it
  can ask the daemon to start, so it's a de facto path to host-level
  privilege escalation (trivially: ask the daemon for a container with
  ``-v /:/host`` and every user-namespace/cap-drop/read-only restriction
  on the *asking* container is irrelevant). Not acceptable, full stop.

  The fix is genuine nested (child, not sibling) rootless containers:
  recursive user-namespace delegation, where the container claude runs in
  gets its own ``/etc/subuid``/``/etc/subgid`` range to further hand out,
  so anything *it* starts is a real child confined within claude's own
  already-restricted uid/gid range -- not a peer of it on a shared
  daemon. Intuition (unverified): doubling the host's per-user
  subuid/subgid range might be enough to cover one level of nesting.
  Needs testing, specifically:

  - Whether doubling the range is actually sufficient sizing, or the
    right number is something else.
  - Whether the (dynamic, per-invocation) subuid/subgid allocation
    scales cleanly to an arbitrary number of concurrently running
    instances -- the actual requirement -- rather than just to one.
  - Whether nested rootless podman's storage driver needs ``/dev/fuse``
    (fuse-overlayfs) passed into the outer container, which today's
    hardening flags (``jm-claude(1)``, Container hardening) don't grant.

  If this works it also fully eliminates the Docker-outside-of-Docker
  host-path-mismatch problem (nested-container volumes resolve against
  the *outer* container's own filesystem, so ordinary relative-path
  volumes in a compose file just work -- no host-path-exposing env var,
  and none of the compose-file maintainability cost that workaround has)
  -- and it removes the *security* justification for the separate
  isolated VM specifically, since that VM's only job today is being a
  safe place to hold the shared socket. Worth keeping the VM around
  regardless for defense-in-depth and for hardware/architecture
  flexibility (big machines, specific archs) -- just no longer load
  bearing for containers-running-containers. Also stops the mechanism
  being ssh/external-VM-socket-specific, which is a step toward it
  working the same way under docker, not just podman.

SEE ALSO
========

``jm-claude(1)``, ``jm-claude-design(7)``

.. include:: ../core/common-license.rst
