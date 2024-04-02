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

echo ethernet:OK > /dev/ttymxc1                                                           
echo EndOfTest > /dev/ttymxc1                                                             
echo "" > /dev/ttymxc1  

# Wait for Serial command with the name of the test that needs to be executed
read ethIp < /dev/ttymxc1

if [ $verbose == 1 ]; then  
  echo "Received IP $ethIp"
fi

if [ $verbose == 1 ]; then  
  echo "Starting iperf client"
fi

ping -c 3 $ethIp                                                                          
                                                                                          
if [ $? != 0 ]; then                                                                      
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