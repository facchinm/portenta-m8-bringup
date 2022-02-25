#!/bin/bash

verbose=1
fail=0

echo ""
echo "*************************START MANUFACTURING-TEST-WIFI*************************"
echo ""

if [[ $1 == "-v" ]]; then
   echo "Verbose mode"
   let verbose=1
fi

if [ $verbose == 1 ]; then  
  echo "Checking if the WiFi driver is active..."
fi

# Scan for wlan0
nmcli -t -f general -e yes -m tab dev show wlan0
ret="$(echo $?)"
if [[ $ret != "0" ]]; then
  let fail=1
  if [ $verbose == 1 ]; then
      echo "Device 'wlan1' not found."
  fi
fi

echo ""
echo "**************************END MANUFACTURING-TEST-WIFI**************************"
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