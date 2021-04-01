#!/bin/bash

if [ "$EUID" -ne 0 ];then
	>&2 printf "\e[38;2;255;0;0m[!]\e[0m Please run as root\n"
	exit 1
fi

install-v domtool /usr/bin/domtool

mkdir -p /usr/local/man/man8
install -g 0 -o 0 -m 0644 domtool.8 /usr/local/man/man8/
gzip /usr/local/man/man8/domtool.8
mandb
