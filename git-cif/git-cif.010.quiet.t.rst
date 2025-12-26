-q option tests
###############

setup::

  $ git init -q ./
  $ git config --local user.name "John"
  $ git config --local user.email "john@example.com"
  $ touch a
  $ git add a
  $ git commit -aqm init

no -q::

  $ echo a >> a
  $ git add a
  $ git cif -m ''
  \[master [0-9a-f]{7}\] a (re)
   1 file changed, 1 insertion(+)

with -q::

  $ echo a >> a
  $ git add a
  $ git cif -m '' -q

with -aq::

  $ echo a >> a
  $ git add a
  $ git cif -aq -m ''
