#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

set -e

session=$(t display-message -p '#S')
name=$(realpath --relative-to $HOME/git $(pwd))
t rename-session -t $session $name
