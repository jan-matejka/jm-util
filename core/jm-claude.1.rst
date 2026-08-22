#########
jm-claude
#########

Run safe claude code
####################

:Manual section: 1
:Date: 2026-08-22
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

  jm claude [-p]

OPTIONS
=======

-p --primary    Run a primary claude.

DESCRIPTION
===========

Runs claude isolated to CWD that should be a git-worktree in a hardened
container with read only access to GIT_DIR and read-write access to
the CWD git-worktree sharing authentication with primary claude (``jm claude
-p``) but no other data.

Claude can still build and run containers if configured to use an isolated VM.

Howto
-----

1. Run ``jm claude -p`` and login into claude.

2. ``cd`` into a git-worktree working dir and run ``jm claude`` for isolated
   claude instance.

Threat Model
------------

Claude Code can run arbitrary commands with a pinky promise it will not do
harm.

But for Claude Code to be useful it has to:

1. Have ability to write in the project source code.

2. Read git history for context and for awareness of manual changes made during
   a session.

3. Have ability to build and run containers for validation.

Therefore it is neccessary:

- Claude to run in hardened container to eliminate risk to the host system
  (in absence of namespace breakout exploits)

- Give claude RW access to a worktree via volume mount.

  Giving access to work tree for claude to autonomously make changes to the
  source. Also gives us the ability to run multiple claude instances for
  multiple worktrees in parallel without conflicts.

  This is safe in absence of namespace breakout exploits.

- Give Claude RO access to GIT_DIR via volume.

  This is safe in absence of namespace breakout exploits.

- Give Claude an isolated VM to build and run containers on its own.

  Theoretically there is a way to do this with podman-in-podman but it requires
  a decent amount of privileges to be given to the claude container, increasing
  the attack surface for namespace breakout exploits.

  Therefore an isolated VM is preferred, which is safe in the absence of vm
  breakout exploits and identical method can be used to isolate to a real
  machine for further isolation.


ENVIRONMENT
===========

JM_CLAUDE_IMAGE
  Image to run claude in.

JM_CLAUDE_CONFIG_HOME
  Config home directory for claude.

JM_CLAUDE_DATA_HOME
  Data home directory for claude.

JM_CLAUDE_DATA_PRIMARY_HOME
  Data home directory for primary claude instance. Files needed for
  authentication will be mounted into isolated instances as well.

JM_CLAUDE_DATA_PROJECT_BRANCH_HOME
  Data home directory for isolated claude instances.

JM_CONFIG_KNOWN_HOSTS
  Known hosts file for claude to use for connecting to an isolated VM.
  Can be created with:
  ``$ ssh-keyscan <VM_SANDBOX_HOSTNAME> > ~/.config/jm-util/claude/known_hosts``

JM_CLAUDE_CONTAINER_HOST
  URL to podman socket on the isolated VM for claude.
  E.g. ``ssh://user@machine/.../podman.sock``.

JM_CLAUDE_CONTAINER_SSHKEY
  ssh key for claude to use to connect to the isolated VM.

DEPENDENCIES
============

Your git repository structure is ``<name>/{master|main,<branch-name>}``.

``<branch-name>`` does not contain slash characters ``/``.

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

SEE ALSO
========

* ``man 1 openssl``

.. include:: common-foot.rst
