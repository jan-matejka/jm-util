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
o_type=

# parse args
declare -a pargs
declare -A paargs

zparseopts -K -D -a pargs -A paargs a m: q d w t:
leftovers=()
(( ${pargs[(I)-w]} )) && o_wip=true
(( ${pargs[(I)-a]} )) && o_all=true
(( ${pargs[(I)-d]} )) && o_discrete=true
(( ${pargs[(I)-q]} )) && leftovers+=( -q )
(( ${${(k)paargs}[(I)-m]} )) && o_msg="${paargs[-m]}"
(( ${pargs[(I)-t]} )) && o_type="${paargs[-t]}"

pathspec=()

# printf "args: %s\n" $@ >&2

while (( $# )); do
  case $1 in
  --)
    ;;
  -*)
    leftovers+=( "$1" )
    ;;
  *)
    pathspec+=( "$1" )
  esac
  shift 1
done

if $o_all && ! $o_discrete; then
  leftovers+=( -a )
fi

# printf "leftovers: %s\n" $leftovers >&2
# printf "pathspec: %s\n" $pathspec >&2

# FIXME: these should be in file config that can be committed.
c_lcpp_trim_file_name=$(git config get --default false jmutil.gitcif.lcpp-trim-file-name)
c_lcpp_trim_file_ext=$(git config get --default true jmutil.gitcif.lcpp-trim-file-ext)

status() {
  git -C $root status --porcelain=v2 "$@"
}

status_to_filenames() {
  local filter="${1}"
  local rename_print="${2}"
  # FIXME: rename_print could removed as an argument to this function (not from
  # the awk itself) if lcpp would split files on both \n and (" " or maybe \t
  # instead if that expands to multiple argv through the xargs pipeline).
  # Because then we could probably use the same input for both lcpp and for the
  # xargs pipeline in -d mode.
  awk -F'[ \t]+' "$filter"' { if ($1==1) print $9; else if ($1==2) { '"$rename_print"' } }'
}

$o_all && {
  # match all changes except to untracked or ignored files
  filter='$1 ~ "1|2"'
} || {
  # match any change in index
  filter='$1 ~ "1|2" && $2 ~ "[^.]."'
}

if ! $o_discrete; then
  local st
  local -a st_xy cc
  local subject

  if (( ${#pathspec} )); then
    # FIXME: this is bad
    if $o_all; then
      addable=( $pathspec )
    else
      addable=($(status -- "${pathspec[@]}" | awk '$1 != "2" { print $9 }'))
    fi
    if (( ${#addable} )) ; then
      git -C $root add -- "${addable[@]}"
    fi
  fi
  # Refresh status after git-add. Under -a the final commit isn't
  # restricted to pathspec, so the scope must be computed from
  # everything that will actually be committed.
  if $o_all; then
    st=$(status)
  else
    st=$(status -- "${pathspec[@]}")
  fi
  st_xy=(${(f)"$(print -r -- "$st" | awk "$filter { print \$2 }")"})
  lcpp=$(print -r -- "$st" | status_to_filenames $filter 'print $10; print $11' | jm-lcpp)

  # apply trimming rules before scope-rewrites because we are checking for file
  # existence.
  if $c_lcpp_trim_file_name && test -f $lcpp && [[ $lcpp == */* ]]; then
    lcpp=${lcpp%/*}
  elif $c_lcpp_trim_file_ext && test -f $lcpp && [[ ${lcpp:t} == ?*.* ]]; then
    lcpp=${lcpp%.*}
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

  if (( ${#st_xy} == 1 )); then
    # Single file commit automation.
    case ${st_xy[1]:0:1} in
    A)
      o_msg="add ${o_msg}"
      ;;
    D)
      if ! (( ${pargs[(I)-t]} )); then
        o_type='rm'
      fi
      ;;
    R)
      if ! (( ${pargs[(I)-t]} )); then
        o_type='mv'
      fi
      if ! (( ${pargs[(I)-m]} )) && (( ${#pathspec} )); then
        o_msg="${pathspec[1]} -> ${pathspec[2]}"
      fi
    ;;
    esac
  fi

  # add cc type
  [[ -n $o_type ]] && cc=( "$o_type" )

  # add scope
  [[ -n $lcpp ]] && cc+=( "$lcpp" )

  subject=${(j.:.)cc}

  # add message
  [[ -n $o_msg ]] && subject="${subject}: $o_msg"

  # add wip prefix
  $o_wip && subject="wip:${subject}"

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

  if [[ -n $subject ]] || (( ${${(k)paargs}[(I)-m]} )); then
    leftovers+=( -m "$subject" )
  fi
  set -- "${leftovers[@]}"
  if ! $o_all; then
    set -- "$@" -- "${pathspec[@]}"
  fi
  git -C $root commit "$@"
  exit $?
else
  $o_wip && leftovers+=( -w )
  leftovers+=( -m "$o_msg" )
  set -- "${leftovers[@]}"

  # For the output of status porcelain refer to dram/99-ref-git-status-porcelain-v2.rst in addition to
  # the git-status(1)
  status | \
    status_to_filenames $filter 'print $10 " " $11;' | \
    xargs -r -L 1 git -C $root cif "$@" --
fi
