#!/usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude
set -e

args=( --oneline --decorate --graph)
exec git log $args
