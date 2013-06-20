#! /bin/sh

. $HOME/.config/tmux-picker/config

list_sessions() {
	tmux ls | grep '^[a-z-]\+:' | cut -f 1 -d " " | sed 's/:$//'
}

main() {
	IFS=""
	sessions=`list_sessions`
	chosen=`echo $sessions | dmenu`
	[ -z $chosen ] && return 0

	if echo $sessions | grep -E "^$chosen$"; then
		$term -e sh -c "tmux at -t $chosen" &
	else
		$term -e sh -c "tmux new -s $chosen" &
	fi
}

main $@
