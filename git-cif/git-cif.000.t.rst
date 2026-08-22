Basic sanity tests
##################

git-cif prints error if it can not find work dir root::

  $ git cif
  fatal: not a git repository .* (re)
  Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
  git-cif: fatal: failed to find work dir
  [1]
