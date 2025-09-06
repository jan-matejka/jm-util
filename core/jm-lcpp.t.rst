test::

  $ jm-lcpp <<EOF
  > foo/bar
  > EOF
  foo/bar

  $ jm-lcpp
  $ jm-lcpp <<EOF
  > foo/bar
  > foo/qux
  > EOF
  foo

  $ jm-lcpp <<EOF
  > foo/bar
  > foo/baz
  > EOF
  foo

  $ jm-lcpp <<EOF
  > foo/bar
  > foo/baz
  > fo
  > EOF

  $ jm-lcpp <<EOF
  > foo
  > foo
  > EOF
  foo

  $ jm-lcpp <<EOF
  > foo/bar/q/1
  > foo/bar/q/2
  > foo/bar/qux
  > foo/bar/quy
  > foo/bar/quyd
  > EOF
  foo/bar

  $ jm-lcpp <<EOF
  > foo/q/1
  > foo/a/1
  > foo/q/4
  > EOF
  foo

  $ jm-lcpp <<EOF
  > a
  > a/b/c
  > b/a
  > EOF
