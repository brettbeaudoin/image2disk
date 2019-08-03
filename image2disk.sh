#!/bin/bash

##################################################################
# Require sudo right away to avoid confusion later
##################################################################
sudo echo 

##################################################################
# Get image file from args or prompt
##################################################################
ARG=$1
if [ "$ARG" == "" ]; then
	echo -n "Enter path to image file and press [ENTER]: "
	read IMGFILE
elif [ -f "$ARG" ]; then
	IMGFILE="$ARG"
else
	echo "Can't find $ARG"
	exit
fi

if [ ! -f "$IMGFILE" ]; then
	echo "Can't find $IMGFILE"
	exit
fi


##################################################################
# Get devices and sizes
##################################################################
DEVS=`diskutil list | grep '/dev/disk' | grep 'external, physical' | awk '{print $1}'`

CHOICES=()
for DEV in $DEVS; do
	SIZE=`diskutil info $DEV | grep 'Disk Size' | awk -F ':' '{print $2}' | awk '{print $1$2}'`
	CHOICES+="$DEV...($SIZE) "
done

PS3="Enter the number of the disk to burn to: "
DEV=''
select CHOICE in $CHOICES; do
	case $CHOICE in
		*)
			DEV=${CHOICE%%...*}
			DEVNUM=`echo $DEV | sed 's/[^0-9]*//g'`
			break
			;;
	esac
done

##################################################################
# Prompt for verification and then burn the image
##################################################################
read -r -p "This will destroy any data on $DEV . Are you sure? [y/N] " response
case "$response" in
	[yY][eE][sS]|[yY]) 
		echo "Unmounting $DEV"
		diskutil unmountDisk $DEV

		echo "Burning $IMGFILE to /dev/rdisk$DEVNUM .  This will take several minutes."
		if [[ "$OSTYPE" == "darwin"* ]]; then
			# MacOS expects 1m (lowercase)
			sudo dd if="$IMGFILE" of=/dev/rdisk$DEVNUM bs=1m
		else
			# Linux expexts 1M (uppercase)
			sudo dd if="$IMGFILE" of=/dev/rdisk$DEVNUM bs=1M
		fi
		
		echo "Ejecting $IMGFILE ..."
		diskutil eject "$DEV"
		;;
	*)
		echo "Aborting..."
		;;
esac

