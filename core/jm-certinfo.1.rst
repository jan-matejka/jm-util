jm-certinfo
###########

Print certificate information
-----------------------------

:Manual section: 1
:Date: 2018-06-17
:Author: Jan Matějka jan@matejka.ninja
:Manual group: jm-util manual

SYNOPSIS
========

  jm certinfo [-h <hostname>] [-p <port>] <protocol> <host>

  <protocol> = www | imap | imaps | smtp | smtps | smtp-msa | file

OPTIONS
=======

-p <port>       port to connect to. If omitted, default is chosen depending on <protocol>.

-h <hostname>   hostname to connect to. Default to <host>. This option is mostly relevant to the www
                protocol when one testing server that is not pointed to by <host> DNS.

DESCRIPTION
===========

Wrapper around ``man 1 openssl`` to make getting cert information easier - I do not remember all the
options needed and even if I did, I want to type something shorter.

<protocol> mostly determines default port to connect to and protocol specific openssl options. Except
"file" protocol where <host> is treated as file path instead.

SEE ALSO
========

* ``man 1 openssl``

.. include:: common-foot.rst
