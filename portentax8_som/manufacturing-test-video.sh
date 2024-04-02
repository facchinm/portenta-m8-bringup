#!/bin/bash

verbose=0
fail=0

echo ""
echo "*************************START MANUFACTURING-TEST-VIDEO*************************"
echo ""

if [[ $1 == "-v" ]]; then
   echo "Verbose mode"
   let verbose=1
fi
echo 109 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio109/direction
echo 1 > /sys/class/gpio/gpio109/value
sleep 1
echo 0 > /sys/class/gpio/gpio109/value

TIMEOUT_SEC=10
start_time="$(date -u +%s)"

while [ ! -c  /dev/fb0 ]; do
echo no fb0
sleep 1
current_time="$(date -u +%s)"
elapsed_seconds=$(($current_time-$start_time))
if [ $elapsed_seconds -gt $TIMEOUT_SEC ]; then
  TIMEOUT_SEC=20
  echo "Retrying to turn on the video"
  echo 109 > /sys/class/gpio/export                                                      
  echo out > /sys/class/gpio/gpio109/direction
  echo 1 > /sys/class/gpio/gpio109/value      
  sleep 1                                     
  echo 0 > /sys/class/gpio/gpio109/value      
fi
done

#echo video:OK > /dev/ttymxc1
#echo EndOfTest > /dev/ttymxc1

# Send the RGB frame
echo 0 > /sys/class/graphics/fbcon/cursor_blink
cat /unit_tests/Display/testcard-1920x1080-bgra.rgb > /dev/fb0

ret="$(echo $?)"
if [[ $ret != "0" ]]; then
  let fail=1
  if [ $verbose == 1 ]; then
      echo "Unable to write RGB image to framebuffer"
  fi
fi

echo ""
echo "**************************END MANUFACTURING-TEST-VIDEO**************************"
echo ""

if [ $fail == 1 ]; then
   echo "FAIL"
   echo ""
   echo ""
   exit 1
else
  echo "PASS"
   echo ""
   echo ""
  exit 0
fi