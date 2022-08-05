#! /usr/bin/env zsh

SELF="${0##*/}"
. yt_prelude

venv=~/.venv/yt/bin/activate
[[ -e $venv ]] || fatal "%s does not exist" $venv

source $venv
python3 `which yt_urltitle.py` $@
