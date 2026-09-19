######################
jm-claude-vm-harness
######################

jm-claude VM/harness architecture exploration
###############################################

:Manual section: 7
:Date: 2026-09-19
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual
:Status: Exploration checkpoint, not a design. Nothing here is
  implemented and nothing here is finally decided unless explicitly
  marked resolved. Written to survive a break in the conversation that
  produced it, not as documentation of current behavior -- see
  ``jm-claude-design(7)`` for that.

WHY THIS EXISTS
================

``jm-claude`` today runs one podman container per repository/worktree,
locally, with an elaborate bind-mount/git-dir-shadow mechanism so ``/src``
looks like a live view of the host's real work tree without ever letting
the container touch the host's real ``.git`` (``jm-claude-design(7)``).

That design is being reconsidered, prompted by a concrete, lived problem:
running several Claude Code agents *concurrently* has stopped scaling the
way the old multi-worktree/tmux workflow did. This document is a
checkpoint of everything worked out so far on a replacement shape, and
what's still open, written down specifically so the thread can be picked
up later without re-deriving it from a chat transcript.

THE ACTUAL PROBLEM (motivation)
=================================

Pre-agentic multi-workspace juggling (one git worktree = one tmux session
= one workspace, ~5 of them) worked because only one workspace was ever
*truly* active at a time -- switching into another was a cheap context
switch into something idle, occasionally doing real work while a test
suite ran elsewhere.

Concurrent coding agents break that assumption: every workspace with an
agent in it is genuinely, simultaneously active. Around 4 concurrently
running agents was enough to become unmanageable this way. The suspected
root cause: the requirement of one git worktree (hence one tmux session,
hence one full local workspace) per agent.

TARGET ARCHITECTURE
=====================

Shape agreed on so far; mechanics of several pieces are still open (see
`OPEN QUESTIONS`_).

Workspace collapse
--------------------

- The user's local machine keeps exactly **one** git worktree, used as a
  "viewport" -- not tied to any single agent. Switching attention to a
  different agent/branch is an ordinary, cheap ``git checkout <branch>``
  in that one worktree, done only when the user actually wants to look
  at or hand-edit that branch's state.
- Every other agent keeps running untouched, in its own checkout,
  independent of what the local viewport currently has checked out.

Per-agent instance keying: branch, not worktree (RESOLVED)
--------------------------------------------------------------

Worktree-keying (``jm-claude-design(7)``, Instance keying;
``jm-claude-todo(7)``) was only ever correct because ``/src`` was a live
bind-mount of one specific worktree's on-disk files -- the instance had
to be tied to whichever worktree it was mounted from. Once that live-mount
requirement is gone, there is no structural reason left to tie an
instance to a worktree at all. A branch name is sufficient, and it's what
actually lets N agents run concurrently without N host worktrees.

Status: decided, not implemented. Today's code (``jm-claude_.zsh``) still
keys ``instance_name``/``instance_fs``/``LOCAL_GITDIR`` on
``worktree_name``. ``jm-claude-todo(7)`` has the pointer.

No host-worktree bind-mount (already partly proven)
-------------------------------------------------------

``-w``/``--isolated-workdir`` (``jm-claude(1)``, already implemented)
already demonstrates that dropping the live host bind-mount entirely
works: the container gets its own persistent, ordinary git checkout,
seeded from committed content, synced only by git push/pull. The target
architecture generalizes this (branch-keyed instead of worktree-keyed,
above) rather than replacing it with something new.

This also means the current ``LOCAL_GITDIR`` seeding/alternates-shadowing
/gitlink-file machinery (most of ``jm-claude-design(7)``) and the shared
bare repo + live-sync ``post-receive`` hard-reset mechanism become
unnecessary in this architecture -- ordinary push/pull is enough once
nothing needs to look like a live bind-mount of a host worktree. (Note
for later cleanup: several existing ``jm-claude-todo(7)`` items are about
that exact machinery -- e.g. the live-sync ``reset --hard`` hazard
mitigation -- and may become moot rather than need solving, once this
lands.)

Per-instance containment is kept, not dropped
--------------------------------------------------

Early framing of this idea considered running Claude Code as a raw,
unconfined process directly on a VM (matching what the vendor assumes by
default). Rejected: that drops today's per-instance hardening
(``--cap-drop=ALL``/``--read-only``/``--no-new-privileges``, userns) and,
more importantly, isolation *between* concurrently running instances --
multiple raw processes sharing one VM with no boundary between them means
one compromised/misbehaving agent session can potentially reach another
repo's checkout or credentials on the same box. Each agent instance keeps
its own hardened podman container; only *where* that container runs and
*how it's reached* changes.

Agents run on a separate host from the user's real workstation
--------------------------------------------------------------------

Originally proposed as load-bearing for isolation (Claude Code "looks
like" the vendor-assumed default of running on a normal machine, but that
machine is a disposable/isolated VM, not the user's actual workstation).
Downgraded (see `Nested containers`_ below) to defense-in-depth and
hardware/architecture flexibility (big machines, specific archs) rather
than being required for security -- it is no longer the thing that makes
nested container creation safe.

UI Harness
------------

A locally-containerized UI Harness, run on the user's actual workstation,
lets the user pick which agent/session to view output from or send input
to -- independent of what the local viewport worktree has checked out.
Its exact implementation is the least settled part of this document; see
`OPEN QUESTIONS`_.

NESTED CONTAINERS (security finding, direction resolved, mechanics unverified)
==================================================================================

Claude's containers must never be able to reach a shared podman/docker
socket to start **sibling** containers -- today's Remote-VM mechanism
(``jm-claude(1)``, ENVIRONMENT/DEPENDENCIES:
``JM_CLAUDE_CONTAINER_HOST``/``CONTAINER_SSHKEY``/etc.) does exactly
this. A shared daemon socket has no confinement relationship between
whoever holds it and what they can ask the daemon to start: trivially,
``-v /:/host`` on a sibling container makes every hardening flag on the
*asking* container irrelevant. Not acceptable.

The fix is genuine nested (child, not sibling) rootless containers:
recursive user-namespace delegation, where the container Claude runs in
gets its own ``/etc/subuid``/``/etc/subgid`` range to further hand out,
so anything it starts is a real child confined within Claude's own
already-restricted uid/gid range -- not a peer of it on a shared daemon.

This also fully eliminates the Docker-outside-of-Docker (DooD) host-path
-mismatch problem for free: a real child container's volumes resolve
against its *parent's own filesystem*, so ordinary relative-path bind
mounts in a compose file just work -- no host-path-exposing env var, no
managed volumes, and ``git clean -fdx``-style hygiene keeps working
exactly as today (an earlier workaround of exposing the real host path
via an env var was considered and dropped -- it has real compose-file
maintainability cost that this fix avoids entirely).

It also removes the *security* justification for the separate isolated
VM specifically (its only remaining job today is being a safe place to
hold the shared socket) -- hence the VM being downgraded to
defense-in-depth/hardware-flexibility above -- and drops the
ssh/external-VM-socket specifics, a step toward the mechanism working the
same way under docker, not just podman.

Unverified, needs testing (not yet started):

- Intuition: doubling the host's per-user subuid/subgid range might be
  enough to cover one level of nesting. Unconfirmed.
- Whether the (dynamic, per-invocation) subuid/subgid allocation scales
  cleanly to an arbitrary number of *concurrently running* instances --
  the actual requirement -- rather than just to one nested level.
- Whether nested rootless podman's storage driver needs ``/dev/fuse``
  (fuse-overlayfs) passed into the outer container, which today's
  hardening flags don't grant.

EXISTING-TOOLING RESEARCH (done)
===================================

Researched to avoid building the UI Harness and any MCP tooling from
scratch if something suitable already exists. Conclusion: nothing is a
clean drop-in, but the landscape is now mapped.

Claude Code / Anthropic native capabilities
-----------------------------------------------

- Remote Control and Agent View (``claude agents``) are same-machine
  features. Agent View's own multi-session UI is itself built around
  worktree-per-agent -- it doesn't solve the actual problem, it automates
  the pattern being escaped.
- Self-hosted Managed Agents (an ``EnvironmentWorker`` on your own VM,
  sessions created via API, execution stays on your infrastructure) is
  the one genuinely native, self-hostable, multi-session path -- but it's
  a different product from today's podman-based ``jm-claude``, and the
  control UI would still need to be built.
- No native or documented MCP-based "drive a Claude Code session"
  interface exists. Claude Code only ever consumes MCP servers as a
  client; it doesn't expose itself as one.

Open-source landscape
-------------------------

- **Codeman** (MIT) -- closest existing fit. Self-hosted, Docker- or
  SSH-backed sessions, already supports Claude Code, sessions bind to a
  folder/case rather than requiring a worktree per agent, SSE + web
  terminal UI. Worth prototyping against directly.
- **agentorc** (MIT) -- same idea; multi-host/container support is on
  its roadmap, not shipped yet.
- **OpenHands** (MIT) -- right shape (controller + per-session isolated
  containers + multi-backend UI) but drives its own agent, not Claude
  Code directly -- would need real adapting.
- Vibe Kanban, Conductor, and generic tmux-based agent dashboards: not a
  fit (worktree-per-agent and/or not self-hostable).
- No MCP-based "remote-control an agent" pattern exists anywhere as a
  standard -- every project in this space does bespoke tmux+SSH/SSE
  instead. Conclusion: MCP in this architecture should be scoped to
  Claude-as-MCP-*client* (git/container/read-only-monitoring tool
  providers), not to the control/driving link, which needs a different,
  already-proven mechanism (Codeman-style).

RELATED, ALREADY-SHIPPED CHANGES
====================================

Landed on ``claude/wip`` this session, ahead of and informing the above:

- ``-w``/``--isolated-workdir`` (``jm-claude(1)``) -- proves dropping the
  host bind-mount works.
- ``instance_name``/``instance_fs`` keyed on absolute ``COMMON_DIR``
  instead of a docker-compose-derived project name (collision-free, but
  names are long/unreadable -- separate open item, see
  ``jm-claude-todo(7)``).

OPEN QUESTIONS
================

Roughly in the order they'd need resolving to move toward a spec:

1. UI Harness: build on Codeman, adapt OpenHands, evaluate agentorc once
   its multi-host support ships, or something else? No prototype done
   yet.
2. Exact transport for the UI Harness <-> agent-instance control link.
   Codeman-style tmux+SSE looks like the right shape; not chosen.
3. Whether Managed Agents (Anthropic's own self-hosted product) should
   replace ``jm-claude``'s podman-based approach wholesale, or whether
   ``jm-claude``'s own container/git plumbing stays and only gets a
   harness bolted in front of it.
4. Nested-container mechanics: subuid/subgid range sizing, scaling to N
   concurrent (possibly also nested) instances, ``/dev/fuse`` requirement
   -- none tested yet.
5. Whether/how the isolated VM survives in its downgraded
   (defense-in-depth-only) role, and in what form.
6. A readable, topology-aware instance-naming scheme (separate from the
   branch-vs-worktree keying question, which is resolved) -- not
   designed.
7. "Project" terminology currently means one git common-dir repo per
   session; whether multi-repo projects are even a valid way to think
   about this (versus re-architecting a multi-repo project to look like
   one repo) is explicitly unresolved and not currently in scope.
8. Reconcile ``jm-claude-todo(7)``'s existing items against this
   direction once it's further along -- several (the live-sync
   ``reset --hard`` hazard mitigation in particular) are about machinery
   this architecture may drop entirely, and would become moot rather
   than need solving.

Unrelated item raised in the same session, not part of this thread:
a container-entrypoint build-staleness check (refuse to start on a stale
build unless ``-f``/``--force``) -- see ``jm-claude-todo(7)``.

SEE ALSO
==========

``jm-claude(1)``, ``jm-claude-design(7)``, ``jm-claude-todo(7)``

.. include:: ../core/common-license.rst
