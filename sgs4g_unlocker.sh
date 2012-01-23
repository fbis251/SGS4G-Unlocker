#!/bin/sh
working=/sdcard/bml

echo Creating temporary directory
mkdir $working/

echo Dumping nv_data.bin
dd if=/efs/root/afs/settings/nv_data.bin of=$working/nv_data.bin

echo Doing hex dump
od -t x1 -A n -v --width=20480 /sdcard/bml/nv_data.bin > $working/od.txt 

echo Finding unlock code
grep -io -m 1 -E 'ff 0[01] 00 00 00 00 [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* [0-9a-f]* ff ' $working/od.txt > $working/unlock.txt

code=''
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

echo Removing temporary directory
rm -r $working/

# We didn't find the unlock code
if [ $code = "00000000" || $code = "" ];then
    echo
    echo "Unlock code not found.  Please ensure:"
    echo "- Your phone is a Samsung Galaxy S 4G"
    echo "  with model number SGH-T959V."
    echo "- Your phone is rooted."
    echo "- You have Busybox installed."
    echo "  -- If so, ensure Busybox is updated to the"
    echo "     latest version."
    echo
exit 1
fi

echo
echo $code
echo

echo Saving unlock code in /sdcard/unlock_code.txt
echo $code > /sdcard/unlock_code.txt

echo Done!

