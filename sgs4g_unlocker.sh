#!/bin/sh
# SGS4G Unlocker version 0.8
# Created by Fernando Barillas (FBis251)
# Contributions by Stephen Williams (stephen_w )

# Initialize variables
BB="which busybox"

WORKING=/sdcard/unlocker_temporary
CODE=''
_DEBUG="off"

# Check to see if we should output debug messages
if [ "$1" == "-x" ];then
  _DEBUG="on"
fi

# Make sure that we only run debug commands when needed
DEBUG() {
  [ "$_DEBUG" == "on" ] &&  $@
}

# Errors
ERROR () {
    case $1 in
	1)
	    # nv_data.bin file not found
	    echo
	    echo "nv_data.bin file not found.  Please ensure:"
	    echo "- Your phone is a Samsung Galaxy S 4G"
	    echo "  with model number SGH-T959V."
	    echo
	    ;;
	2)
	    # Unlock code not found
	    echo
	    echo "Unlock code not found.  Please ensure:"
	    echo "- Your phone is a Samsung Galaxy S 4G"
	    echo "  with model number SGH-T959V."
	    echo "- Your phone is rooted."
	    echo "- You have Busybox installed."
	    echo "  -- If so, ensure Busybox is updated to the"
	    echo "     latest version."
	    echo
	    ;;
    3)
        echo
        echo "Busybox is not installed correctly!"
        echo "- Please follow the instructions in"
        echo "  the unlocker thread."
        echo
        ;;
    esac
    DEBUG echo Removing temporary directory
    $BB rm -rf $WORKING/
    exit $1
}

if [ "$BB" == "" ];then
    ERROR 1
fi

DEBUG echo Creating temporary directory
$BB mkdir -p $WORKING/

# Look for nv_data.bin
if [ ! -e /efs/root/afs/settings/nv_data.bin ]; then
    ERROR 2
fi

DEBUG echo Dumping nv_data.bin
if [ "$_DEBUG" == "on" ]; then
  # Show dd's output
  $BB dd if=/efs/root/afs/settings/nv_data.bin of=$WORKING/nv_data.bin
else
  # Not in debug mode so we need to redirect dd's output
  $BB dd if=/efs/root/afs/settings/nv_data.bin of=$WORKING/nv_data.bin > /dev/null > /dev/null 2>&1
fi

DEBUG echo Doing hex dump
$BB od -t x1 -A n -v --width=20480 $WORKING/nv_data.bin > $WORKING/od.txt

DEBUG echo Finding unlock code
$BB grep -io -m 1 -E 'ff 0[01] 00 00 00 00 [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* ff ' $WORKING/od.txt > $WORKING/unlock.txt

for f in `cat $WORKING/unlock.txt`
do
  # Convert the hex number to decimal output
  num=$((0x$f))
  # We only want ascii values for 0-9
  if [ $num -ge 48 ]
  then
    if [ $num -le 57 ]
    then
      # We found the correct ascii values so to get them to decimals just
      # subtract 48
      CODE=$CODE$(($num-48))
    fi
  fi
done

DEBUG echo Removing temporary directory
$BB rm -rf $WORKING/

# We didn't find the unlock code
if [ "$CODE" == "00000000" -o "$CODE" == "" ];then
    ERROR 3
fi

echo Unlock code found:
echo
echo $CODE
echo

echo Saving unlock code in /sdcard/unlock_code.txt
echo $CODE > /sdcard/unlock_code.txt

echo Done!
exit 0
