initialize a repository with a root commit::

  $ git init -q ./
  $ git config --local user.name "John"
  $ git config --local user.email "john@example.com"
  $ touch a
  $ git add a
  $ git commit -qam 'setup'

git-cif reads jmutil.gitcif.lcpp-trim-file-ext from the
[tool.jmutil.gitcif] table of project.toml::

  $ mkdir tomlcfg
  $ echo x > tomlcfg/thing.txt
  $ git add tomlcfg
  $ git commit -qam 'setup tomlcfg'
  $ printf '[tool.jmutil.gitcif]\nlcpp-trim-file-ext = false\n' > project.toml
  $ echo >> tomlcfg/thing.txt
  $ git add tomlcfg/thing.txt
  $ EDITOR=: git cif -q
  $ git log -1 --pretty=%s
  tomlcfg/thing.txt

pyproject.toml is used as a fallback when project.toml doesn't exist::

  $ rm project.toml
  $ printf '[tool.jmutil.gitcif]\nlcpp-trim-file-ext = false\n' > pyproject.toml
  $ echo >> tomlcfg/thing.txt
  $ git add tomlcfg/thing.txt
  $ EDITOR=: git cif -q
  $ git log -1 --pretty=%s
  tomlcfg/thing.txt

git-cif falls back to the hardcoded default -- with a warning, not an
error -- when project.toml is syntactically invalid TOML::

  $ rm -f pyproject.toml
  $ mkdir badcfg
  $ echo x > badcfg/thing.txt
  $ git add badcfg
  $ git commit -qam 'setup badcfg'
  $ printf 'this is not valid [[[ toml' > project.toml
  $ echo >> badcfg/thing.txt
  $ git add badcfg/thing.txt
  $ EDITOR=: git cif -q
  Error: bad file '*project.toml': expected character = (glob)
  Error: bad file '*project.toml': expected character = (glob)
  Error: bad file '*project.toml': expected character = (glob)
  $ git log -1 --pretty=%s
  badcfg/thing

an invalid project.toml still falls through to a valid pyproject.toml,
rather than aborting outright::

  $ printf '[tool.jmutil.gitcif]\nlcpp-trim-file-ext = false\n' > pyproject.toml
  $ echo >> badcfg/thing.txt
  $ git add badcfg/thing.txt
  $ EDITOR=: git cif -q
  Error: bad file '*project.toml': expected character = (glob)
  Error: bad file '*project.toml': expected character = (glob)
  Error: bad file '*project.toml': expected character = (glob)
  $ git log -1 --pretty=%s
  badcfg/thing.txt
  $ rm -f project.toml pyproject.toml
