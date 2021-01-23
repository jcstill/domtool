#!/bin/bash

# VOLUME GROUP FREE SPACE = 

DOMNAME=
DIST=bionic

VCPUS=1
MEMORY=1gb
SIZE=15gb
SWAP=2gb
LVM=vg0

IP=
GATEWAY=192.168.1.1
NETMASK=255.255.255.0
NAMESERVER=192.168.1.1

CREDIT=256

cleanup() {
	rm /home/jacob/tmp.cfg
	sed -i "$(grep -n DOMNAME < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/DOMNAME=/" "$0"
	sed -i "$(grep -n IP < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/IP=/" "$0"
	sed -i "$(grep -n DIST < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/DIST=bionic/" "$0"
	sed -i "$(grep -n VCPUS < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/VCPUS=1/" "$0"
	sed -i "$(grep -n MEMORY < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/MEMORY=1gb/" "$0"
	sed -i "$(grep -n SIZE < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/SIZE=15gb/" "$0"
	sed -i "$(grep -n SWAP < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/SWAP=2gb/" "$0"
	sed -i "$(grep -n LVM < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/LVM=vg0/" "$0"
	sed -i "$(grep -n GATEWAY < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/GATEWAY=192.168.1.1/" "$0"
	sed -i "$(grep -n NETMASK < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/NETMASK=255.255.255.0/" "$0"
	sed -i "$(grep -n NAMESERVER < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/NAMESERVER=192.168.1.1/" "$0"
	sed -i "$(grep -n CREDIT < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/CREDIT=256/" "$0"
	sed -i "$(grep -n VOLUME < "$0" | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/# VOLUME GROUP FREE SPACE = $(sudo pvs --units g|tail -1|awk 'NF>1{print $NF}')/" "$0"
	exit
}

STARTTIME="$(date +%s)"
if [ "$EUID" -ne 0 ];then
	printf "\e[38;2;255;0;0m[!]\e[0m Please run as root\n"
	exit
fi
if [ -z "$DOMNAME" ] || [ -z "$DIST" ] || [ -z "$VCPUS" ] || [ -z "$MEMORY" ] || [ -z "$SIZE" ] || [ -z "$SWAP" ] || [ -z "$LVM" ] || [ -z "$IP" ] || [ -z "$GATEWAY" ] || [ -z "$NETMASK" ] || [ -z "$NAMESERVER" ];then
	printf "\e[38;2;255;0;0m[!]\e[0m Please edit the variables in this file\n"
	exit
fi

xen-create-image --hostname="$DOMNAME" --memory="$MEMORY" --vcpus="$VCPUS" --size="$SIZE" --swap="$SWAP" --dist="$DIST" --ip="$IP" --gateway="$GATEWAY" --netmask="$NETMASK" --nameserver="$NAMESERVER" --lvm="$LVM" --noboot

if [ ! -f /etc/xen/"$DOMNAME".cfg ];then
	printf "\e[38;2;255;0;0m[!]\e[0m /etc/xen/%s.cfg doesn't exist. xen-create-image must have failed. exiting.\n" "$DOMNAME"
	cleanup
fi
cp /etc/xen/"$DOMNAME".cfg /home/jacob/tmp.cfg
TYPE="$(grep -n type < /home/jacob/tmp.cfg)"
if [[ -z $TYPE ]];then
	sed -i "s/bootloader = 'pygrub'/type=\n\nbootloader = 'pygrub'/" /home/jacob/tmp.cfg
fi
sed -i "$(grep -n type < /home/jacob/tmp.cfg | tr ':' ' ' | awk '{print $1}')s/.*/type= 'pvh'/" /home/jacob/tmp.cfg
MAC="$(printf '%02X:%s\n' "$(( $(printf '%d\n' $((16#$(openssl rand -hex 1)))) & 254 ))" "$(openssl rand -hex 5 | sed 's/\(..\)/\1:/g; s/:$//')" | sed -e 's/\(.*\)/\U\1/')"
IP="$(grep vif < /home/jacob/tmp.cfg | tr "'" ' ' | tr ',[]' '\n' | grep ip | awk '{print $1}')"
REP="vif = [ '$IP, mac=$MAC, bridge=xenbr0' ]"
sed -i "$(grep -n vif < /home/jacob/tmp.cfg | tr ':' ' ' | awk '{print $1}')s/.*/$REP/" /home/jacob/tmp.cfg
cp /home/jacob/tmp.cfg /etc/xen/"$DOMNAME".cfg

RTPASS="$(grep "Root Password" < /var/log/xen-tools/"$DOMNAME".log | awk '{print $4}')"
printf "\e[38;2;0;255;0m[+]\e[0m Root Password: %s\n" "$RTPASS"
xl create /etc/xen/"$DOMNAME".cfg
IP="$(echo "$IP" | tr '=' ' ' | awk '{print $2}')"
DOMU="$(ping -c 1 -q "$IP" | grep transmitted | awk '{print $4}')"
while [ "$DOMU" -ne 1 ];do
	DOMU="$(ping -c 1 -q "$IP" | grep transmitted | awk '{print $4}')"
	sleep 1
done

sed -i "$(grep -n "fi" < /home/jacob/xentools/updatehost | tr ':' ' ' | awk '{print $1}' | head -1)s/.*/fi\nxl sched-credit -d $DOMNAME -w $CREDIT/" /home/jacob/xentools/updatehost

ENDTIME="$(date +%s)"
TOTALTIME=$((ENDTIME-STARTTIME))
TOTALTIME="$(date -d@$TOTALTIME -u +%H:%M:%S)"
printf "\e[38;2;0;255;0m[+]\e[0m Script Time: %s\n" "$TOTALTIME"

echo "sudo xl console $DOMNAME"
cleanup
