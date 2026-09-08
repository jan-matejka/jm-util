initialize a repository with a root commit::

  $ git init -q ./
  $ git config --local user.name "John"
  $ git config --local user.email "john@example.com"
  $ touch a
  $ git add a
  $ git commit -qam 'setup'

komitr trims the file extension depending on its setting::

  $ mkdir -p foo/bar/qux
  $ touch foo/bar/qux/file.pp
  $ git add foo
  $ EDITOR=: komitr -aq
  $ git log -1 --pretty=%s
  ft:foo/bar/qux/file: add
  $ echo >> foo/bar/qux/file.pp
  $ printf '[tool.komitr]\nlcpp-trim-file-ext = false\n' > project.toml
  $ EDITOR=: komitr -aq
  $ git log -1 --pretty=%s
  foo/bar/qux/file.pp


komitr trims the file name portion if enabled::

  $ printf '[tool.komitr]\nlcpp-trim-file-name = true\n' > project.toml
  $ echo >>foo/bar/qux/file.pp
  $ EDITOR=: komitr -aq
  $ git log -1 --pretty=%s
  foo/bar/qux

trimming applies in discrete mode as well::

  $ echo >>foo/bar/qux/file.pp
  $ EDITOR=: komitr -aqd
  $ git log -1 --pretty=%s
  foo/bar/qux

extension trimming still applies when invoked from a subdirectory, not
just from the work tree root -- lcpp is always root-relative, so the
existence check backing the trim must be too::

  $ printf '[tool.komitr]\nlcpp-trim-file-name = false\nlcpp-trim-file-ext = true\n' > project.toml
  $ echo >>foo/bar/qux/file.pp
  $ git add foo/bar/qux/file.pp
  $ cd foo/bar && EDITOR=: komitr -q && cd ../..
  $ git log -1 --pretty=%s
  foo/bar/qux/file

trim does not apply to dotfiles and directories::

  $ mkdir foo/bar.d
  $ touch foo/bar.d/qux
  $ touch foo/.quux
  $ git add foo
  $ komitr -dqam ''
  $ git log -2 --pretty=%s
  ft:foo/bar.d/qux: add
  ft:foo/.quux: add

and doesn't apply to files in work tree root::

  $ echo >>a
  $ EDITOR=: komitr -aq
  $ git log -1 --pretty=%s
  a

komitr applies scope-rewrite rules to the lcpp path::

  $ mkdir -p src/lib
  $ touch src/lib/thing.txt
  $ git add src
  $ printf '[tool.komitr]\nlcpp-trim-file-name = false\nlcpp-trim-file-ext = false\nscope-rewrite = ["s#^src/##"]\n' > project.toml
  $ EDITOR=: komitr -aq
  $ git log -1 --pretty=%s
  ft:lib/thing.txt: add

scope-rewrite applies to discrete mode as well::

  $ echo >>src/lib/thing.txt
  $ EDITOR=: komitr -aqd
  $ git log -1 --pretty=%s
  lib/thing.txt

rules apply in the order they appear in the array::

  $ echo >> src/lib/thing.txt
  $ printf '[tool.komitr]\nlcpp-trim-file-name = false\nlcpp-trim-file-ext = false\nscope-rewrite = ["s#^src/##", "s/lib/vendor/"]\n' > project.toml
  $ EDITOR=: komitr -aq
  $ git log -1 --pretty=%s
  vendor/thing.txt
