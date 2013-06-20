#! /bin/sh

. $HOME/.config/tmux-picker/config

list_sessions() {
	tmux ls | grep '^[a-z-]\+:' | cut -f 1 -d " " | sed 's/:$//'
}

main() {
	chosen=`list_sessions | dmenu`
	[ -z $chosen ] && return 0

	$term -e sh -c "tmux at -t $chosen" &
}

main $@
