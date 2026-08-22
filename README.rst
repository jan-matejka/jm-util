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

Build
#####

``$ make``

Installation
############

``# make install`` or ``$ make install-home``

Tests
#####

Requires docker-compose and podman.

``$ podman compose build dev && podman compose run dev make check``

While it should be possible to run tests on host it is not recommended for your
own safety.
