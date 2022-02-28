#!/bin/bash

verbose=1
fail=0
clockVal=50000000

echo ""
echo "*************************START MANUFACTURING-TEST-SDCARD*************************"
echo ""

if [[ $1 == "-v" ]]; then
   echo "Verbose mode"
   let verbose=1
fi

if [ $verbose == 1 ]; then  
  echo "Checking if the SDCARD is properly mounted..."
fi

# Check if mmc1 is correctly mounted
cat /sys/kernel/debug/mmc1/ios | grep clock | awk -v col=2 '{print $col}'
ret="$(echo $?)"
if [[ $ret != "0" ]]; then
  let fail=1
  if [ $verbose == 1 ]; then
      echo "Error with mmc1"
  fi
fi

# Check clock value
clock=$(cat /sys/kernel/debug/mmc1/ios | grep clock | awk -v col=2 '{print $col}')
if [[ $clock != $clockVal ]]; then
  let fail=1
  if [ $verbose == 1 ]; then
      echo "Invalid clock $clock"
  fi
fi

echo ""
echo "**************************END MANUFACTURING-TEST-SDCARD**************************"
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