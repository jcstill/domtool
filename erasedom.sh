#!/bin/bash

if [ "$EUID" -ne 0 ];then
	>&2 printf "Please run as root\n"
	exit
fi

if [ -z "$1" ];then
	>&2 printf "Please specify the domU to erase\n"
	exit
fi

echo "This will irreversibly delete data."
echo -n "Are you sure you want to completely erase $1 [Y/n]?"
read -r DELETE

if [ "$DELETE" == "Y" ];then
	sudo xl destroy "$1"
	sleep 1
	sudo rm -rf /etc/xen/"$1".cfg
	sleep 1
	sudo umount /dev/vg0/"$1"-swap
	sudo umount /dev/vg0/"$1"-disk
	sleep 1
	sudo lvchange -an /dev/vg0/"$1"-swap
	sleep 1
	sudo lvchange -an /dev/vg0/"$1"-disk
	sleep 1
	sudo lvremove /dev/vg0/"$1"-swap -y
	sleep 1
	sudo lvremove /dev/vg0/"$1"-disk -y
else
	echo Not Deleting.
fi
exit
