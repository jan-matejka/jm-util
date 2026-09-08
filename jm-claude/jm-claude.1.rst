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

- the current working directory is bind-mounted into /src (claude's working
  directory), and

- claude's repository is added as a ``claude-<work-tree-name>`` git-remote in
  the host repository, and

- the current branch is set up to track claude's branch, unless in a
  git-worktree whose name does not match the current branch.

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
    transparently visible to claude but not the commits you make. Claude needs
    to explicitly pull them.

    This will likely cause issues for claude when you restart it without
    continuing the previous session.

ENVIRONMENT
===========

Standard
--------

JM_CLAUDE_IMAGE
  Image to run claude in.

JM_CLAUDE_CONFIG_HOME
  Config home directory for claude.

  Shared across all instances.

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

  FIXME: unclear how to resolve with different --acount.

JM_CLAUDE_CONTAINER_HOST
  URL to podman socket on the isolated VM for claude.
  E.g. ``ssh://user@machine/.../podman.sock``.

  This is instance specific but intended to be shared.

  FIXME: unclear how to resolve with different --acount.

JM_CLAUDE_CONTAINER_SSHKEY
  ssh key for claude to use to connect to the isolated VM.

  This is instance specific but intended to be shared.

  FIXME: unclear how to resolve with different --acount.

FILES
=====

jm-claude reads the following keys from ``project.toml`` or
``pyproject.toml`` in the work tree root, whichever is found first:

tool.jmutil.claude.account
  see -a `OPTIONS`_.

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

Claude has RW access to a git-dir on the host.

Claude has RO access only to the git-dir backing the working directory's work
tree.

Known hazards
-------------

- It is not safe for the user to modify the working directory on the host
  (including switching branches) while claude is actively working on it.

- Claude has access to the network, including private networks.

- The volume shadowing in security sensitive contexts is sus.

Container hardening
-------------------

Techniques applied:

- podman

  - ``--read-only``
  - ``--cap-drop=ALL``
  - ``--security-opt=no-new-privileges``

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

  - WIP: Doesn't work right yet.

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
      (somewhat) work.

    - Enabled the user's podman.socket and `# loginctl enable-linger <user>`.

    - An authorized_keys entry for the JM_CLAUDE_CONTAINER_SSHKEY.
      The entry can have options:
      ``restrict,port-forwarding,command="/bin/false"`` for _some_ additional
      safety. It does nothing for security tho.

    - If using libvirt:

      - ``virt-sysprep`` is useful.

      - You'll probably want to have:

        - a separate bridged network for the VM.

        - Default DROP policies for FORWARD and INPUT chains in iptables.

        - Allow forwarding only to public networks.

.. include:: ../core/common-foot.rst
