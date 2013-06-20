#! /bin/sh

. $HOME/.config/tmux-picker/config

list_sessions() {
	tmux ls | grep '^[a-z-]\+:' | cut -f 1 -d " " | sed 's/:$//'
}

chosen=`list_sessions | dmenu`
$term -e sh -c "tmux at -t $chosen" &

