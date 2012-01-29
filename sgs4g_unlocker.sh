#!/bin/sh
# SGS4G Unlocker version 0.6
# Created by Fernando Barillas (FBis251)

# Initialize variables
working=/sdcard/unlocker_temporary
code=''

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
    esac
    DEBUG echo Removing temporary directory
    rm -r $working/
    exit $1
}

DEBUG echo Creating temporary directory
mkdir $working/

# Look for nv_data.bin
if [ ! -e /efs/root/afs/settings/nv_data.bin ]; then
    ERROR 1
fi
    
DEBUG echo Dumping nv_data.bin
dd if=/efs/root/afs/settings/nv_data.bin of=$working/nv_data.bin > /dev/null > /dev/null 2>&1

DEBUG echo Doing hex dump
od -t x1 -A n -v --width=20480 $working/nv_data.bin > $working/od.txt 

DEBUG echo Finding unlock code
grep -io -m 1 -E 'ff 0[01] 00 00 00 00 [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* ff ' $working/od.txt > $working/unlock.txt

for f in `cat $working/unlock.txt`
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
      code=$code$(($num-48))
    fi
  fi
done

DEBUG echo Removing temporary directory
rm -r $working/

# We didn't find the unlock code
if [ "$code" == "00000000" -o "$code" == "" ];then
    ERROR 2
fi

echo Unlock code found:
echo
echo $code
echo

echo Saving unlock code in /sdcard/unlock_code.txt
echo $code > /sdcard/unlock_code.txt

echo Done!
exit 0
