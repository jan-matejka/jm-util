Input Validation And Transport Errors
#####################################

git-cl rejects a URL that isn't http(s):// or host:path.git shaped::

  $ git-cl not-a-valid-url
  git-cl: fatal: Invalid url=not-a-valid-url
  [1]

git-cl requires the URL path to be exactly org/repo, rejecting a path
with too few::

  $ git-cl https://example.com/onlyonesegment
  git-cl: fatal: Invalid path=onlyonesegment
  [1]

or too many segments::

  $ git-cl https://example.com/a/b/c
  git-cl: fatal: Invalid path=a/b/c
  [1]

git-cl warns about plain http:// before attempting the clone::

  $ mkdir insecure-dest
  $ git-cl http://127.0.0.1:1/myorg/myrepo.git "$PWD/insecure-dest"
  git-cl: warning: unsecure transport
  fatal: unable to access 'http://127.0.0.1:1/myorg/myrepo.git/': Failed to connect to 127.0.0.1 port 1 after * ms: Could not connect to server (glob)
  [128]
