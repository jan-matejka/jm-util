#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

log_dir=$HOME/.local/share

redir -1 /dev/null pgrep -f '^xscreensaver' || {
  xscreensaver -no-capture-stderr -verbose -log $log_dir/xscreensaver.log &
  sleep 1
  # FIXME: need to wait until xscreensaver is ready to receive the '-lock'
  # maybe check if it creates a socket or something.
}


xscreensaver-command -lock
