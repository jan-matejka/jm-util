Input Validation And Transport Errors
#####################################

gytr-cl rejects a URL that isn't http(s):// or host:path.git shaped::

  $ gytr-cl not-a-valid-url
  gytr-cl: fatal: Invalid url=not-a-valid-url
  [1]

gytr-cl requires the URL path to be exactly org/repo, rejecting a path
with too few::

  $ gytr-cl https://example.com/onlyonesegment
  gytr-cl: fatal: Invalid path=onlyonesegment
  [1]

or too many segments::

  $ gytr-cl https://example.com/a/b/c
  gytr-cl: fatal: Invalid path=a/b/c
  [1]

gytr-cl warns about plain http:// before attempting the clone::

  $ mkdir insecure-dest
  $ gytr-cl http://127.0.0.1:1/myorg/myrepo.git "$PWD/insecure-dest"
  gytr-cl: warning: unsecure transport
  fatal: unable to access 'http://127.0.0.1:1/myorg/myrepo.git/': Failed to connect to 127.0.0.1 port 1 after * ms: Could not connect to server (glob)
  [128]
