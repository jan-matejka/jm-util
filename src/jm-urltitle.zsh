#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

venv=~/.venv/jm/bin/activate
[[ -e $venv ]] || fatal "%s does not exist" $venv

source $venv
pjmhon3 `which jm_urltitle.py` $@
