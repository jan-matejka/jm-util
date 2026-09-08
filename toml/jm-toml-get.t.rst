not a git repository::

  $ jm toml-get tool.jmutil.claude.account
  jm-toml-get: fatal: not a git repository (re)
  [1]

setup a repository::

  $ git init -q ./
  $ git config --local user.name John
  $ git config --local user.email john@example.com
  $ touch a; git add a; git commit -qam setup

reads a present key from project.toml::

  $ printf '[tool.jmutil.claude]\naccount = "work"\n' > project.toml
  $ jm toml-get tool.jmutil.claude.account
  work

exits 1 with no output for an absent key and no default::

  $ jm toml-get tool.jmutil.claude.missing
  [1]

prints the default and exits 0 for an absent key when yq successfully
determined the key is absent::

  $ jm toml-get tool.jmutil.claude.missing fallback
  fallback

pyproject.toml is used as a fallback when project.toml doesn't have the key::

  $ printf '[tool.jmutil.claude]\nother = "x"\n' > project.toml
  $ printf '[tool.jmutil.claude]\naccount = "fromfallback"\n' > pyproject.toml
  $ jm toml-get tool.jmutil.claude.account
  fromfallback
  $ rm -f project.toml pyproject.toml

trailing [] reads an array, one element per line::

  $ printf '[tool.jmutil.gitcif]\nscope-rewrite = ["a", "b"]\n' > project.toml
  $ jm toml-get 'tool.jmutil.gitcif.scope-rewrite[]'
  a
  b
  $ rm -f project.toml

a single-level (undotted) key is read at the document root::

  $ printf 'toplevel = "yes"\n' > project.toml
  $ jm toml-get toplevel
  yes
  $ rm -f project.toml

reading an array key without a trailing []::

  $ printf 'x = 1\n' > project.toml
  $ jm toml-get tool.jmutil.gitcif.scope-rewrite
  [1]

reading a scalar key with a trailing []::

  $ jm toml-get 'toplevel[]'
  [1]
  $ rm -f project.toml

yq-detection and no-yq-fallback tests, which all need to override PATH
to be deterministic, live in jm-toml-get.yq-detection.t.rst instead.
