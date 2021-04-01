#!/bin/bash

if [ "$EUID" -ne 0 ];then
	>&2 printf "\e[38;2;255;0;0m[!]\e[0m Please run as root\n"
	exit 1
fi

install -v domtool /usr/bin/domtool

install -v -g 0 -o 0 -m 0640 domtool.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable domtool.service
systemctl restart domtool.service

mkdir -vp /usr/local/man/man8
install -v -g 0 -o 0 -m 0644 domtool.8 /usr/local/man/man8/
gzip -vf /usr/local/man/man8/domtool.8
mandb
