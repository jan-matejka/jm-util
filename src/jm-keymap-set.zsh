#! /usr/bin/env zsh

SELF="${0##*/}"
. yt_prelude

check-arg "name" ${1:-}
name=$1

args=($(cat $YT_CONFIG_HOME/keymap/$name)) || fatal "Unknown %s" $name
notifier=(dzen2 -sa c -xs 1 -p 1)

if setxkbmap $args ; then
  echo "keymap: $name" | $notifier
else
  echo "failed to set keymap $name" | $notifier
fi
