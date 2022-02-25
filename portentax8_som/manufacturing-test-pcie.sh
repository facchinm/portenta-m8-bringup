#!/bin/bash

verbose=1
fail=0

echo ""
echo "*************************START MANUFACTURING-TEST-PCIEXPRESS*************************"
echo ""

if [[ $1 == "-v" ]]; then
   echo "Verbose mode"
   let verbose=1
fi

if [ $verbose == 1 ]; then  
  echo "Checking if the PCIExpress module is working..."
fi

# Check if is able to found the PCIExpress device
out=$(lspci -mm)
if [ -z $out ]; then
  let fail=1
  if [ $verbose == 1 ]; then
      echo "No PCIExpress decive detected"
  fi
fi

echo ""
echo "**************************END MANUFACTURING-TEST-PCIEXPRESS**************************"
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