#######
jm-util
#######

My personal collection of utilities.

The more interesting ones are:

- jm claude

    Runs fully isolated Claude Code.

- git-cif

    git commit helper to pre-fill commit message with longest common prefix
    path of the files being committed.

- jm-alias

    shell aliases but as real commands so they can be passed to xargs,
    exec, etc.

- versionator

    Generates a debian compatible version from git repository.

- jm tmux-dmenu

    dmenu for tmux sessions.


Installation
############

Debian
======

Available through my PPA https://github.com/jan-matejka/debian-ppa::

  # curl -fsSL https://jan-matejka.github.io/debian-ppa/install | sh
  # apt install jm-util

From source
===========

into home::

  $ make build install-home

or into system::

  $ make
  # make install

For dependencies see ``./oci/Containerfile``.

Tests
#####

Requires docker-compose and podman.

``$ podman compose build work && podman compose run work make check``

While it should be possible to run tests on host it is not recommended for your
own safety.

Release Management
##################

``make packages`` can be called any time and will build either release package
or dev package depeneding on git state.

To actually release a package::

  $ make release version=<version-literal>
  $ make packages
  ... continue in debian-ppa
