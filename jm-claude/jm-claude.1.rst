#########
jm-claude
#########

Run Claude Code, safe-ishly
###########################

:Manual section: 1
:Date: 2026-09-07
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

  jm claude [opts] <args>

DESCRIPTION
===========

Runs claude in a hardened ephemeral container with authentication persistence
and git discovery.

If running inside a git repository:

- HEAD must be on a branch (fails otherwise), and

- the current branch is switched into the ``claude/`` namespace first,
  unless it is already there: ``claude/<branch>`` is created fresh off it,
  or an existing ``claude/<branch>`` is fast-forwarded onto it (failing if
  that isn't a fast-forward) -- so the branch you keep upstreaming from is
  never the one claude commits to directly, and

- the current working directory is bind-mounted into /src (claude's working
  directory), and

- one shared bare repository per repository (not per work tree) is added as
  a ``claude`` git-remote in the host repository, and

- the current branch is set up to track it, and

- claude's own git-dir also has a ``claude`` remote, pointing at the same
  shared repository from inside the container, and tracks its branch there
  too -- so a plain ``git push``/``git pull`` works from either side without
  naming the remote.

``<work-tree-name>`` = the git-worktree name, if currently in one.
``<work-tree-name>`` = basename <work-tree-root>, otherwise.

See `SAFETY`_ and `EXAMPLES`_ for more.

OPTIONS
=======

-p --primary
  Run a primary instance of claude.

-a <account>, --account <account>
  Arbitrary file system path compatible string.

  Used for distinguishing between different claude accounts.

  Defaults to config key tool.jmutil.claude.account (`FILES`_) if it exists,
  otherwise ``default``.

  Scopes persistent state to the account: ``JM_CLAUDE_CONFIG_HOME_ACCOUNT``,
  ``JM_CLAUDE_DATA_PRIMARY_HOME``, and the volumes for XDG_CONFIG_HOME, and
  XDG_DATA_HOME inside the container are both keyed by ``<account>``.

-i <instance>, --instance <instance>
  Instance name for the container.
  Mounts ``JM_CLAUDE_DATA_INSTANCE_SRC`` into /src.

-e --exec
  Exec run zsh inside the running container instance.

<args>
  Passed to podman-run <image> <args...> so you can run e.g. ``jm claude zsh``.

EXAMPLES
========

Initialization
--------------

1. ``jm claude -p``, log into claude, and exit.

Standard operation
------------------

- ``jm claude -i <instance>`` for claude without working directory.

- ``jm claude`` within a git repository for claude with the repository and work
  tree context.

- You can monitor the progress claude is making by observing the working
  directory.

- Once claude finishes, you can commit yourself on the host or git-pull if you
  let claude commit.

  Known issues:

  - You need to do git reset --hard && git clean -fd or clean the working
    directory manually before git-pull, otherwise git-pull refuses to operate.

  - When you make changes on the host, the working directory contents are
    transparently visible to claude, but a *commit* is not, until it is
    *pushed* to the ``claude`` remote (by you, or by claude, or by a user
    ``jm claude -e``'d into the running container). Once pushed, it is
    applied live: the shared repository's ``post-receive`` hook resets the
    owning work tree straight to what was just pushed, so claude sees it
    immediately without restarting.

    A push landing while claude has uncommitted work in progress in that
    work tree will discard it -- ``reset --hard`` does not stash first.

  - See ``jm-claude-design(7)`` for the shared-repository/live-sync
    mechanism in detail.

  - Requires relative .git link files. (>=git-2.48).

ENVIRONMENT
===========

Standard
--------

JM_CLAUDE_IMAGE
  Image to run claude in.

JM_CLAUDE_CONFIG_HOME
  Config home directory for claude, parent of the per-account config
  directory (``JM_CLAUDE_CONFIG_HOME_ACCOUNT``).

JM_CLAUDE_CONFIG_HOME_ACCOUNT
  Config directory for claude, mounted into ``~/.config/claude`` in the
  container.

  Account specific (-a `OPTIONS`_). Parented to ``JM_CLAUDE_CONFIG_HOME`` by
  default.

JM_CLAUDE_CONFIG_SKILLS

  Directory to mount into ~/.claude/skills in the container.

JM_CLAUDE_DATA_HOME
  Data home directory for claude.

  This is used as default parent for:
  - JM_CLAUDE_DATA_PRIMARY_HOME
  - JM_CLAUDE_DATA_INSTANCE_HOME
  - JM_CLAUDE_DATA_INSTANCE_SRC

JM_CLAUDE_DATA_PRIMARY_HOME
  Data home directory for primary claude instance. Files needed for
  authentication will be mounted into isolated instances as well.

  This is instance specific path parented to JM_CLAUDE_DATA_HOME.

JM_CLAUDE_DATA_INSTANCE_HOME
  Data home directory for the isolated claude instance.

  This is instance specific path parented to JM_CLAUDE_DATA_HOME.

JM_CLAUDE_DATA_INSTANCE_SRC
  path to volume mount into /src when using -i.

  This is instance specific path parented to JM_CLAUDE_DATA_HOME.

Remote VM related
-----------------

JM_CONFIG_KNOWN_HOSTS
  Known hosts file for claude to use for connecting to an isolated VM.
  Can be created with:
  ``$ ssh-keyscan <VM_SANDBOX_HOSTNAME> > ~/.config/jm-util/claude/known_hosts``

  This is instance specific but intended to be shared.

  FIXME: unclear how to resolve with different --account.

JM_CLAUDE_CONTAINER_HOST
  URL to podman socket on the isolated VM for claude.
  E.g. ``ssh://user@machine/.../podman.sock``.

  This is instance specific but intended to be shared.

  FIXME: unclear how to resolve with different --account.

JM_CLAUDE_CONTAINER_SSHKEY
  ssh key for claude to use to connect to the isolated VM.

  This is instance specific but intended to be shared.

  FIXME: unclear how to resolve with different --account.

FILES
=====

jm-claude reads the following keys from ``project.toml`` or
``pyproject.toml`` in the work tree root, whichever is found first:

tool.jmutil.claude.account
  see -a `OPTIONS`_.

tool.jmutil.claude.podman_args
  Array of extra ``podman run`` arguments, e.g.::

    [tool.jmutil.claude]
    podman_args = ["--memory=4g", "-v", "/extra/host:/extra/container"]

  Appended after every flag jm-claude sets itself, right before the image
  name -- so an entry here can override anything jm-claude sets, hardening
  included (`Known hazards`_).

The key's value is read from whichever file has it first.

SAFETY
======

Motivation
----------

Claude Code can run arbitrary commands with a pinky promise it will be useful
and not delete or exfiltrate your secrets and other data.

Therefore we want to execute it only in a sandboxed, isolated environment.
Containers are used because they are lightweight and easy to create and dispose
of.

For Claude Code to be actually useful to its full potential, it typically
needs to have access to the working directory to inspect and modify files
there.

If the working directory is a git repository, it needs to be able to read the
repository history for context and it needs to be able to modify the working
directory.

Ideally, it also needs to be able to author commits.

Furthermore, it is essential for it to be able to run containers itself,
safely (sus, WIP).

Constraints
-----------

Claude has RW access to the working directory (FIXME: this is a footgun and
shall not be the default).

Claude has RW access to its own git-dir on the host, and to a shared bare
repository (also on the host) that every work tree of the same repository
pushes to and is live-synced from.

Claude has RO access only to the git-dir backing the working directory's work
tree.

Known hazards
-------------

- Every invocation switches the host's checked-out branch to
  ``claude/<branch>`` (creating it, or fast-forwarding an existing one --
  failing if that isn't possible) before doing anything else, even without a
  worktree, on whatever branch was checked out.

- ``tool.jmutil.claude.podman_args`` (`FILES`_) is appended last, after
  every hardening flag jm-claude itself sets -- so a ``project.toml`` in a
  repository you don't fully trust can silently disable the sandboxing
  (``--read-only``, ``--cap-drop=ALL``, extra mounts, etc.) for anyone who
  runs jm-claude there.

- It is not safe for the user to modify the working directory on the host
  (including switching branches) while claude is actively working on it.

- A push to the shared repository's branch (by anyone: the host, another
  exec'd shell, claude itself) hard-resets the owning work tree to it. Any
  uncommitted work sitting there at that moment is discarded, not stashed.

- Claude has access to the network, including private networks.

- The volume shadowing in security sensitive contexts is sus.

Container hardening
-------------------

Techniques applied:

- podman

  - ``--read-only``
  - ``--cap-drop=ALL``
  - ``--security-opt=no-new-privileges``

``--init`` is also set, though it isn't a hardening measure: claude runs as
PID 1 in the container and never reaps children, so without it any orphaned
subprocess (a git hook's, or otherwise) sits as a zombie for the container's
whole lifetime.

Would you like to know more?
----------------------------

- ``jm-claude-design(7)`` for the git isolation mechanism in detail.

- ``jm-claude-todo(7)`` for known limitations and planned work.

DEPENDENCIES
============

- docker-compose and podman on the host.

- Activated user socket for podman:

  ``$ systemctl --user enable --now podman.socket``

  Note: the socket needs to be restarted for changes to e.g.
  ${XDG_CONFIG_HOME}/containers/containers.conf to take effect.

- If you want claude to build and run containers:

  - You have to set following variables for jm-claude:

    - JM_CLAUDE_KNOWN_HOSTS
    - JM_CLAUDE_CONTAINER_HOST
    - JM_CLAUDE_CONTAINER_SSHKEY

  - Have an externally managed VM that is externally isolated appropriately.
    i.e. jm-claude can not create, manage, or isolate the VM for you. Its just
    using it.

  - The isolated VM should have

    - podman and docker-compose.

    - The same user and user's home as in the claude container for volumes to
      (somewhat) work (TBD: unclear yet if same user is needed. The paths are
      not aligned yet anyway so rel path volumes dont work anyway but claude
      can just rsync his tree over there and run podman-compose over there).

    - Enabled the user's podman.socket and `# loginctl enable-linger <user>`.

    - An authorized_keys entry for the JM_CLAUDE_CONTAINER_SSHKEY.

    - If using libvirt:

      - ``virt-sysprep`` is useful.

      - You'll probably want to have:

        - a separate bridged network for the VM.

        - Default DROP policies for FORWARD and INPUT chains in iptables.

        - Allow forwarding only to public networks.

.. include:: ../core/common-foot.rst
