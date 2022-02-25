#!/bin/bash

verbose=0
fail=0

echo ""
echo "*************************START MANUFACTURING-TEST-VIDEO*************************"
echo ""

wait_ok () {
   var="$(i2cget -f -y 2 0x0A 0x00 w -W 3)"
   if [[ $var != "0x4b4f" ]]; then
      let fail=1
      if [ $verbose == 1 ]; then
         echo "KO :("
      fi
   fi
   if [[ $var == "0x4b4f" ]] & [ $verbose == 1 ]; then
      echo "OK :)"
   fi
}

if [[ $1 == "-v" ]]; then
   echo "Verbose mode"
   let verbose=1
fi

if [ $verbose == 1 ]; then  
  echo "Checking if the WiFi driver is active..."
fi

DTTADDRESS=0x0A

I2CREADVIDEO=0x0D
I2CCOMPAREVIDEO=0x0E

# Send I2C command I2C_READ_VIDEO (0x0D) to tell the son to enable the frame grabber
if [ $verbose == 1 ]; then
   echo "Sending command to enable frame grabber..."
fi
i2cset -f -y 2 $DTTADDRESS $I2CREADVIDEO c
wait_ok

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

# Send I2C command I2C_COMPARE_VIDEO (0x0D) to tell the son to compare the frame with the template
if [ $verbose == 1 ]; then
   echo "Sending command to check the received frame..."
fi
i2cset -f -y 2 $DTTADDRESS $I2CCOMPAREVIDEO c
wait_ok

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