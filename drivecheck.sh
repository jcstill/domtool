#!/bin/bash
for i in {a..d};do
	echo -n "/dev/sd$i: "
	SMART="$(smartctl -a /dev/sd$i | grep "result\|Power_On_Hours" | tr -d '\n\r' | awk '{print $16 "Hours " $6}' | tr -d '\r\n')"
	MDADM="$(mdadm -E /dev/sd"$i"1 | grep "State" | grep -v "Array State" | awk '{print " " $3}' | tr -d '\r\n')"
	echo $SMART | awk '{print $1 " "}' | tr -d '\r\n'
	if [ -z $(echo $MDADM) ];then
		echo -n "!inary"
	elif [ "$(echo $MDADM)" == "active" ];then
		echo -n "active"
	fi
	echo $SMART | awk '{print "\t| " $2}' | tr -d '\r\n'
	echo
done 2> /dev/null



#sudo mdadm -D /dev/md0 | grep "/dev/" | tail -4 | cut -c 41- | sed -e 's/sync//g' | awk '{print $2 " " $1}'
