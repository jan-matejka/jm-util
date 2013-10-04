#! /bin/sh

. $HOME/.config/tmux-picker/config

filter_attached() {
	grep -v '(attached)'
}

list_sessions() {
	local f1=cat
	[ "${1:-}" = "--no-attached" ] && f1=filter_attached
	tmux ls | $f1 | grep '^[A-Za-z0-9-]\+:' | cut -f 1 -d " " | sed 's/:$//'
}

main() {
	IFS=""
	sessions=`list_sessions $@`
	chosen=`echo $sessions | dmenu`
	[ -z $chosen ] && return 0

	if echo $sessions | grep -E "^$chosen$"; then
		$term -e sh -c "tmux at -t $chosen" &
	else
		$term -e sh -c "tmux new -s $chosen" &
	fi
}

main $@
