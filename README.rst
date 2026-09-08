#######
jm-util
#######

My personal collection of utilities.

The more interesting ones are:

- jm claude

    Runs fully isolated Claude Code.

- komitr

    Git commit helper to pre-fill commit message with longest common prefix
    path of the files being committed.

- jm-alias

    Shell aliases but as real commands so they can be passed to xargs,
    exec, etc.

- versionator

    Generates a Debian compatible version from git repository.

- jm tmux-dmenu

    Dmenu for tmux sessions.


Installation
############

Debian
======

Available through my PPA https://github.com/jan-matejka/debian-ppa::

  # curl -fsSL https://jan-matejka.github.io/debian-ppa/install | sh
  # apt install jm-util

``jm-util`` is a metapackage pulling in every module below. Install a module
directly (e.g. ``apt install komitr``) to skip the rest: jm-util-core,
jm-util-git-lint, jm-util-alias, jm-util-claude, jm-util-p, jm-util-toml,
jm-util-versionator, komitr, gytter.

From source
===========

Build with ``$ podman compose run build``.

Install into home::

  $ make build install-home

Install into system::

  # make install

Note individual modules can be built and installed individually. E.g.: ``make
-C core build check install``.

Dependencies
============

For container build you need only podman (or docker perchance) and
docker-compose.

For the actual dependencies see ``./debian/control`` or ``./Containerfile``.

Tests
#####

``$ podman compose run build``

While it should be possible to run tests on host it is not recommended for your
own safety.

Release Management
##################

``make packages`` can be called any time and will build either release package
or dev package depending on git state.

To actually release a package::

  $ make release version=<version-literal>
  $ make packages
  ... continue in debian-ppa
