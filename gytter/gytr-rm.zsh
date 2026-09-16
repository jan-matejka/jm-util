#!/usr/bin/env zsh

git rm $@

pathspec=()
while (( $# )); do
  case $1 in
  --)
    pathspec+=( -- )
    shift
    ;;
  -*)
    shift
    ;;
  *)
    pathspec+=( $1 )
    shift
  esac
done
