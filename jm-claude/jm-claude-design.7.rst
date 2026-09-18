################
jm-claude-design
################

jm-claude design
################

:Manual section: 7
:Date: 2026-09-08
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

INTENT
======

.. _intent1:

1. jm-claude should work with any git repository topology automatically.

.. _intent2:

2. The repository's git-dir SHALL be mounted into the container in a way that
   is read-write inside the container but changes from inside the container do
   not propagate to the host.


3. The directories SHALL be mounted in a way so:

   .. _intent3:

   1. git commands function normally inside the container, with modifications
      to the current work tree visible on the host's work tree, but

      .. _intent3-1:


   2. the container must not modify the ``.git`` file or directory visible on
      the host.

      .. _intent3-2:

TOPOLOGY RESOLUTION
====================

Computed once, host-side, before the container starts. All four are plain
``git rev-parse``/``test`` results, not container paths.

``ROOT``
  ``git rev-parse --show-toplevel``

``COMMON_DIR``
  Absolute path of ``git rev-parse --git-common-dir``.

``WORK_GIT_DIR``
  Absolute path of ``git rev-parse --git-dir``.

  - Equal to ``COMMON_DIR`` for the default topology and for a repository
    cloned via ``--separate-git-dir`` in the default work tree.
  - Nested under ``COMMON_DIR/worktrees/<name>`` only for git-worktree work
    tree.

``DOTGIT_IS_FILE``
  Whether ``$ROOT/.git`` is a regular file rather than a directory.
  Needed for shadowing (see `MOUNTS`_).

``COMMON_DIR``/``WORK_GIT_DIR`` alone make mounting and seeding
topology-agnostic.

INSTANCE KEYING
================

``jm-claude_.zsh``'s existing instance naming (``instance_name``/
``instance_fs``, e.g. ``p_${project}_${branch}``) is branch-keyed --
switching branches in the same worktree gets a distinct instance.

``LOCAL_GITDIR`` (Mounts, below) is deliberately worktree-keyed instead:

``WORKTREE_NAME``
  See `<work-tree-name>` `jm-claude(1)`.

Worktree-keying gives one ``LOCAL_GITDIR`` per worktree, reused across
branch switches to indicate work tree boundness because of the work tree
mount liveness.

``SHARED_GITDIR`` (Shared repo and live sync, below) is keyed to
``COMMON_DIR`` alone -- one shared bare repository per repository, shared by
every one of its worktrees, not per worktree.

MOUNTS
======

Container-side paths, fixed for the life of the container:

``CT_COMMON``
  - ``/run/jm-claude/git-common-ro``
  - Host's live common git-dir (``COMMON_DIR``) in RO mode.

``CT_WORK``
  git-dir, i.e.

  - host's common git-dir if default topology, in this case CT_WORK =
    CT_COMMON. Or

  - work-tree's git-dir if git-worktree, in this case 
    CT_WORK != CT_COMMON and WORK_GIT_DIR is mounted to CT_WORK.

``CT_LOCAL``
  e.g. ``/run/jm-claude/git-local`` -- where ``LOCAL_GITDIR`` is mounted,
  needed only for the gitlink case below.

``CT_SHARED``
  e.g. ``/run/jm-claude/git-shared`` -- where ``SHARED_GITDIR`` is mounted,
  read-write.

``LOCAL_GITDIR`` is a plain host directory keyed by
``COMMON_DIR/WORKTREE_NAME`` (Instance keying, above), so host-side fetching
is possible and it survives the container's ``--rm``. Seeded host-side
(Seeding, below), before ``podman run``.

``SHARED_GITDIR`` is a plain host directory too, a sibling of every
``LOCAL_GITDIR`` under the same ``COMMON_DIR`` (Shared repo and live sync,
below).

note: Keying to ``realpath --relative-to $HOME $COMMON_DIR`` is tempting.
Unfortunately its more trouble than worth when considering paths outside
``HOME``.


Mounts:

- ``ROOT`` is bind-mounted read-write at ``/src``.
- ``COMMON_DIR`` is bind-mounted read-only at ``CT_COMMON``.
- ``SHARED_GITDIR`` is bind-mounted read-write at ``CT_SHARED``.
- ``WORK_GIT_DIR`` is bind-mounted read-only at ``CT_WORK``, only as a
  distinct mount when it differs from ``COMMON_DIR``.
- ``/src/.git`` is shadowed with a mount pointing at ``LOCAL_GITDIR``,
  layered on top of the ``/src`` bind mount, so the container's git never
  resolves to the host's real git-dir. The shadow's type must match
  whatever the ``/src`` mount already produced at that path (a bind mount
  can't change a mountpoint from file to directory or back):

  - ``$ROOT/.git`` is a directory (default topology): ``LOCAL_GITDIR`` is
    bind-mounted directly at ``/src/.git`` -- seeding populates it
    beforehand. Or
  - ``$ROOT/.git`` is a file (any work tree topology): ``LOCAL_GITDIR`` is
    bind-mounted at ``CT_LOCAL``, and a gitlink file containing
    ``gitdir: CT_LOCAL`` is bind-mounted at ``/src/.git``. The gitlink
    file's content is written host-side, since a bind mount's source must
    already exist as real content at mount time.

- ``LOCAL_GITDIR/objects/info/alternates`` is itself shadowed the same
  way, regardless of topology: a container-valid file, listing
  ``$CT_COMMON/objects`` and ``$CT_SHARED/objects``, is bind-mounted
  read-only over the real, on-disk ``objects/info/alternates``, wherever
  ``LOCAL_GITDIR`` lands (see Host fetchability, below, for why this file
  has two versions at all, and Shared repo and live sync, below, for why
  it needs the second line).

CONTAINER-LOCAL GIT-DIR SEEDING
=================================

Runs once, host-side in ``jm-claude_.zsh``, before ``podman run``.

Once, the first time a work tree is seeded (``$LOCAL_GITDIR/HEAD`` does not
exist yet):

1. ``git init --bare $LOCAL_GITDIR``, then ``git config core.bare false`` --
   a plain ``git init`` would also create a work tree at ``$LOCAL_GITDIR``
   itself, which is never used and would be wrong once ``core.worktree`` is
   pointed at ``/src`` (step 4, below).
2. Carry over the host's committer identity, so a commit made in the
   container doesn't fail with "Author identity unknown": read
   ``user.name``/``user.email`` from ``$ROOT``'s own git config (which
   already resolves through to the global config if the repository has
   none of its own), falling back to the current user / ``user@hostname``
   if neither is set anywhere, and write both into ``$LOCAL_GITDIR``.
3. Write ``$LOCAL_GITDIR/objects/info/alternates`` with two lines,
   ``$COMMON_DIR/objects`` and ``$SHARED_GITDIR/objects`` -- host-valid
   paths, permanent. Read access to all existing history and to anything
   pushed to the shared repo, without copying it. A host's ``git fetch``'s
   ``git-upload-pack`` reads this file directly, from a process running
   entirely on the host with no access to ``CT_COMMON``/``CT_SHARED`` -- it
   does not inherit alternate resolution from the fetching command's own
   environment. The container-valid version lives in a separate file,
   shadowed over this one instead (Mounts, above).
4. Copy the per-worktree state, so the container starts where the host
   currently is, reading from the host paths directly. These are copies,
   not links: they diverge independently from the host from here on.

   - ``$LOCAL_GITDIR/HEAD``  <- ``$WORK_GIT_DIR/HEAD``
   - ``$LOCAL_GITDIR/index`` <- ``$WORK_GIT_DIR/index``, if present
   - ``$LOCAL_GITDIR/refs/heads/$BRANCH`` <- ``$COMMON_DIR/refs/heads/$BRANCH``,
     if ``$BRANCH`` is non-empty and that loose ref exists -- only the one
     ref ``HEAD`` resolves through, not the whole ``refs`` tree, so no other
     branch/tag/remote-tracking ref leaks from the host repo into
     ``LOCAL_GITDIR``. A detached ``HEAD`` needs no ref at all.

Every invocation, whether or not seeding above ran:

5. ``git --git-dir=$LOCAL_GITDIR config core.worktree /src``
6. Point (or re-point) a ``claude`` remote in ``$LOCAL_GITDIR`` at
   ``$CT_SHARED``, and set ``branch.$BRANCH.remote``/``.merge`` to track it
   -- see `SHARED REPO AND LIVE SYNC`_.
7. Write ``$LOCAL_GITDIR.worktree`` with ``$ROOT`` -- see `SHARED REPO AND
   LIVE SYNC`_.
8. If ``$ROOT/.git`` is a file (any work tree topology): write the gitlink
   file containing ``gitdir: CT_LOCAL``.
9. Write ``$LOCAL_GITDIR.alternates`` with ``$CT_COMMON/objects`` and
   ``$CT_SHARED/objects`` -- the container-valid shadow for step 3.

ISOLATION GUARANTEE
=====================

- All writes from git commands run inside the container (new objects, ref
  updates, index changes) land only in the host's ``LOCAL_GITDIR``, designed
  specifically as the container's "out" dir -- `intent2`_.
- ``COMMON_DIR`` and ``WORK_GIT_DIR`` are mounted read-only -- `intent3-2`_.
- Because ``/src/.git`` is shadowed by ``LOCAL_GITDIR`` (directly or via
  gitlink), any git command run from ``/src`` inside the container
  resolves to ``LOCAL_GITDIR`` through ordinary discovery, with no need
  for callers to pass ``--git-dir`` explicitly -- `intent3-1`_.

  FIXME: shadowed shit is probably still accessible inside the container by
  alternate pathing via /proc or something.
  This may actually be a massive hole in the default topology.

  "standard Linux mount-namespace semantics make the shadowed content genuinely
  unreachable from inside the container's own namespace once shadowed —
  /proc/<pid>/root tricks to reach another namespace's pre-shadow view need
  CAP_SYS_ADMIN/CAP_SYS_PTRACE, both of which --cap-drop=ALL removes."
  -- Claude, {citation needed} tho.


HOST FETCHABILITY
===================

``LOCAL_GITDIR`` is an ordinary host directory (Mounts, above), so
``git fetch $LOCAL_GITDIR`` works directly, any time, even while the
container is running and writing to it -- because
``objects/info/alternates`` is host-valid on disk (Seeding step 3, above),
the same file a fetch's ``git-upload-pack`` reads directly.

"There is no shortcut that lets fetch avoid needing this: the server process
has to open its own ancestry-relevant objects to mark them uninteresting during
negotiation, regardless of whether the client already has them by hash, so any
alternate-only object anywhere in the walk -- not just an immediate parent --
would break it." -- Claude Sonnet 5, seems reasonable tho.

SHARED REPO AND LIVE SYNC
===========================

Fetching straight out of ``LOCAL_GITDIR`` (above) is host-initiated and
pull-only. This is the other direction: a way for a push -- from the host,
from claude itself, or from a user ``jm claude -e``'d into the running
container -- to reach the owning work tree immediately, without the
container needing to be involved or even still running.

One more host-side lookup, used only here:

``BRANCH``
  ``git symbolic-ref --short HEAD`` (current branch name).

``SHARED_GITDIR``
  ``git init --bare``, created once per ``COMMON_DIR`` if it doesn't exist
  yet (Instance keying, above).

Remotes, both pointing at ``SHARED_GITDIR``, both named ``claude``:

- Host-side, in ``$ROOT`` (``COMMON_DIR``): points at ``SHARED_GITDIR``'s
  host path directly.
- Container-side, in ``LOCAL_GITDIR`` (Seeding step 6, above): points at
  ``CT_SHARED``, so it only ever resolves from inside a container that has
  it mounted.

Branch tracking (``branch.$BRANCH.remote``/``branch.$BRANCH.merge``,
enabling plain ``git pull``/``git status``/``git push`` with no arguments)
is set unconditionally, both in ``LOCAL_GITDIR`` -- it only ever has the
one branch it was seeded with -- and host-side, regardless of whether
``BRANCH`` equals ``WORKTREE_NAME``.

Live sync (post-receive hook)
------------------------------

``SHARED_GITDIR/hooks/post-receive`` is (re)written on every invocation, so
it always matches the currently running ``jm-claude_.zsh``. It runs,
as usual for a git hook, wherever the push landed -- inside a container's
mount namespace for a push that went through ``CT_SHARED``, as a genuine
host process for a push straight at ``SHARED_GITDIR``'s host path.

For each updated ``refs/heads/<branch>``, it needs the owning work tree's
``LOCAL_GITDIR``/work-tree pair:

- ``LOCAL_GITDIR`` is found by relative path, ``../<branch>`` from
  ``SHARED_GITDIR`` -- both are siblings under
  ``$JM_CLAUDE_DATA_HOME/gitdir/$COMMON_DIR`` (Instance keying, above), and
  a git hook runs with its cwd set to the (bare) repo it fired in. This
  also makes a push landing inside a container harmless on its own: only
  the container's own fixed ``/run/jm-claude/git-{local,shared,...}``
  mounts exist there, not a path named after the branch, so the lookup
  simply finds nothing and no-ops.
- The work tree path is read from ``LOCAL_GITDIR.worktree`` (Seeding step
  7, above) -- ``LOCAL_GITDIR``'s own ``core.worktree`` is set to the
  container-only ``/src`` (Seeding step 5), unusable from the host.

If that work tree is already sitting at the pushed revision -- always true
for a push that just came from claude's own checked-out branch, since you
can't push a commit you don't already have -- the hook no-ops. Otherwise:
``git --git-dir=$LOCAL_GITDIR --work-tree=<worktree> reset --hard
<pushed-revision>``, straight onto the real, bind-mounted work tree. A
running container's ``/src`` is that same bind mount, so it sees the
change immediately -- no restart needed.

This is also why ``LOCAL_GITDIR``'s alternates need ``SHARED_GITDIR/objects``
(Mounts, above): the reset target may only exist there, never copied into
``LOCAL_GITDIR``'s own object store.

KNOWN HAZARDS
==============

Switching branches on the host while a container is running desyncs the
live ``/src`` mount from ``LOCAL_GITDIR``'s ``HEAD``/index: the working
tree updates immediately (a live bind mount), but ``LOCAL_GITDIR``'s
``HEAD``/index were only ever a one-time copy taken when the container
started, so the two diverge silently. See ``jm-claude-todo(7)`` for a
possible mitigation.

The live-sync ``reset --hard`` (Shared repo and live sync, above) does not
stash first: a push landing on a branch while its work tree has uncommitted
changes -- claude's own in-progress edits included -- discards them.

SEE ALSO
========

``jm-claude(1)``, ``jm-claude-todo(7)``

.. include:: ../core/common-foot.rst
