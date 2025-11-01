jm-keymap
#########

X keymap toggle
---------------

:Manual section: 1
:Date: 2018-06-16
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

Executes each line of the <name> config file as argv to ``man 1 setxkbmap``.

::

  jm keymap set <name>

CONFIGURATION
=============

<name> is file name in the $XDG_CONFIG_HOME/jm-util/keymap/ directory.

SEE ALSO
========

* ``man 1 jm-keymap-toggle``
* ``man 1 setxkbmap``

.. include:: common-foot.rst
