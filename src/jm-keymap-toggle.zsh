#! /usr/bin/env zsh

SELF="${0##*/}"
. jm_prelude

names=($(zargs -n1 -- $JM_CONFIG_HOME/keymap/* -- basename))

current=$(setxkbmap -query | grep layout: | sed 's/ \+/ /g' | cut -f2 -d" ")

idx=${names[(I)$current]}

(( $idx )) || fatal "could not recognize current layout"

# calculate next index.
# - modulo cycles back to first item if we are on last one.
# - increment comes after modulo since zsh arrays start at 1.
idx=$(( (( $idx % ${#names} )) + 1 ))

exec jm-keymap-set ${names[$idx]}
