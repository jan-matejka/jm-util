#! /usr/bin/env bash

usage() {
	echo "Usage: $0 <command> <command_args>"
}

main() {
    case "$1" in
        table-flip)
            echo "(╯°□°）╯︵ ┻━┻"
            ;;
        *)
            echo "idk" >&1
            return 1
        ;;
    esac
}
