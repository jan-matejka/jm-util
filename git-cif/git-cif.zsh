#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude
set -e

root=$(git rev-parse --show-toplevel) || fatal "failed to find work dir"

# opts
o_all=false
o_msg=""
o_quiet=false
o_discrete=false
o_wip=false

# parse args
declare -a pargs
declare -A paargs

zparseopts -K -D -a pargs -A paargs a m: q d w
(( ${pargs[(I)-w]} )) && o_wip=true
(( ${pargs[(I)-a]} )) && o_all=true
(( ${pargs[(I)-d]} )) && o_discrete=true
(( ${pargs[(I)-q]} )) && set -- -q $@
(( ${${(k)paargs}[(I)-m]} )) && o_msg="${paargs[-m]}"

# FIXME: these should be in file config that can be committed.
c_lcpp_trim_file_name=$(git config get --default false jmutil.gitcif.lcpp-trim-file-name)
c_lcpp_trim_file_ext=$(git config get --default true jmutil.gitcif.lcpp-trim-file-ext)

status() {
  git -C $root status --porcelain=v2
}

$o_all && {
  # match all changes except to untracked or ignored files
  filter='$1 ~ "1|2"'
  commit_opts=( -a )
} || {
  # match any change in index
  filter='$1 ~ "1|2" && $2 ~ "[^.]."'
  commit_opts=( )
}

! $o_discrete && {
  local st
  local -a st_xy pathspec

  if [[ -n ${JM_GITCIF_PATHSPEC:-} ]]; then
    pathspec=( -- "$JM_GITCIF_PATHSPEC" )
    # discrete mode recurses once per file, passing it via env
    # XY is how is this field referenced in the git-status man page.
    st_xy=( $(git -C $root status --porcelain=v2 -- "$JM_GITCIF_PATHSPEC" |
      awk '{ print $2 }') )
    lcpp=$JM_GITCIF_PATHSPEC
  else
    st=$(status)
    st_xy=(${(f)"$(print -r -- "$st" | awk "$filter { print \$2 }")"})
    lcpp=$(print -r -- "$st" | awk "$filter { print \$9 }" | jm-lcpp)
  fi

  # apply configured scope-rewrite rules (sed s/// expressions), in the
  # order they appear in git config, e.g.:
  #   git config set --local --append jmutil.gitcif.scope-rewrite 's/^foo\/src\//foo\//'
  local -a scope_rewrite_rules sed_args
  scope_rewrite_rules=(${(f)"$(git -C $root config get --all jmutil.gitcif.scope-rewrite || true)"})
  (( ${#scope_rewrite_rules} )) && {
    sed_args=()
    for r in "${scope_rewrite_rules[@]}"; do
      sed_args+=(-e "$r")
    done
    lcpp=$(print -r -- "$lcpp" | sed "${sed_args[@]}")
  }

  # apply trimming rules
  if $c_lcpp_trim_file_name && test -f $lcpp && [[ $lcpp == */* ]]; then
    lcpp=${lcpp%/*}
  elif $c_lcpp_trim_file_ext && test -f $lcpp && [[ $lcpp == *.* ]]; then
    lcpp=${lcpp%.*}
  fi

  # append custom message if passed
  if [[ -n $o_msg ]]; then
    o_msg="$lcpp: $o_msg"
  else
    o_msg="$lcpp"
  fi

  # add "add: " prefix if committing a sole newly tracked file
  (( ${#st_xy} == 1 )) && [[ ${st_xy[1]:0:1} == A ]] && o_msg="add: ${o_msg}"

  # add wip prefix
  $o_wip && o_msg="wip: ${o_msg}"

  # open EDITOR only if -m is not given
  (( ${${(k)paargs}[(I)-m]} )) || commit_opts+=( --edit )

  # override EDITOR to start it with cursor placed at the end of the commit message subject
  [[ ${${EDITOR:-}[1,3]} = "vim" ]] && export EDITOR='vim -c "normal A"'

  # Passing the default message into git via stdin is messing with running
  # editor so that is not an option.

  # stdin here may be the read end of a pipe rather than a terminal (discrete
  # mode recursion).
  #
  # That's fine for `git commit -m` itself, but if commit.gpgsign is on and
  # pinentry is curses-based, gpg needs a real tty on stdin to prompt for the
  # passphrase.
  #
  # The line below tests if tty is available and re-attaches it if it is.
  #
  # Note there may be no tty at all, e.g. in CI.
  zsh -c ': </dev/tty' 2>/dev/null && exec 0</dev/tty

  git -C $root commit $@ $commit_opts -m "$o_msg" $pathspec
  (( $? > 0 )) && exit 255
  exit 0
} || {
  $o_wip && set -- -w $@
  set -- $@ -m "$o_msg"

  # For the output of status porcelain refer to dram/99-ref-git-status-porcelain-v2.rst in addition to
  # the git-status(1)
  status | \
    awk "$filter { print \$9 }" | \
    xargs -r -I{} env JM_GITCIF_PATHSPEC={} git -C $root cif "$@"
}
