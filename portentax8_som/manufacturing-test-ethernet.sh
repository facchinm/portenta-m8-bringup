#!/bin/bash

verbose=0
fail=0

echo ""
echo "*************************START MANUFACTURING-TEST-ETHERNET*************************"
echo ""

#Update the test with NanoPi IP
NANOPI_IP="30.30.30.2"

if [[ $1 == "-v" ]]; then
   echo "Verbose mode"
   let verbose=1
fi

if [ $verbose == 1 ]; then  
  echo "Configuring board with static IP 30.30.30.1/24"
fi
nmcli con mod "Wired connection 1" ipv4.addresses "30.30.30.1/24"
nmcli con mod "Wired connection 1" ipv4.method manual
nmcli con mod "Wired connection 1" connection.autoconnect yes

if [ $verbose == 1 ]; then  
  echo "Starting iperf client"
fi

iperf3 -i 10 -t 60 -c $NANOPI_IP
ret="$(echo $?)"
if [ ret != "0" ]; then
  let fail=1
fi

echo ""
echo "**************************END MANUFACTURING-TEST-ETHERNET**************************"
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