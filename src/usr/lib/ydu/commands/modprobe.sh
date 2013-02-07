#! /bin/sh

main() {
	if [ $# -eq 1 ] && [ "$1" = "-l" ]; then
		find /lib/modules/`uname -r` -type f -name "*.ko" -exec basename {} \; | sed 's/\.ko$//'
		return
	fi

	`which modprobe` $@
}