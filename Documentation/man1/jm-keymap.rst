yt-keymap
#########

X keymap toggle
---------------

:Manual section: 1
:Date: 2018-06-16
:Author: Jan Matějka jan@matejka.ninja
:Manual group: yac tools manual

SYNOPSIS
========

::

  yt keymap toggle
  yt keymap set <name>

CONFIGURATION
=============

<name> is identified by file names in $XDG_CONFIG_HOME/yac-tools/keymap/ directory.
Contents of the filename are arguments for ``man 1 setxkbmap`` to use when the <name> is set.

For toggle to work, the <name> must be same as layout printed by ``setxkbmap -query``.

SEE ALSO
========

* ``man 1 setxkbmap``

.. include:: ../common-foot.rst
