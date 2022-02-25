#!/bin/bash

# This script runs each peripheral test.
# To add a peripheral test, add the peripheral name ("peripheral1") to the x8Tests array
# This name must match the script name (manufacturing-test-peripheral1.sh)

# To enable verbose mode for the main test, run ./manufacturing-test-x8.sh -v
# To enable verbose mode for the main test and the peripheral subtests, run ./manufacturing-test-x8.sh -v -all

x8Tests=("gpio" "wifi" "ethernet" "sdcard" "pcie") #Add also video

verbose=0
verbose_all_tests=0
fail=0
pass=0

echo ""
echo "*************************START MANUFACTURING-TEST-X8*************************"
echo ""

if [[ $1 == *"-v"* ]]; then
   echo "Verbose mode for main test"
   let verbose=1
fi

if [[ $2 == "-all" ]]; then
   echo "Verbose mode for all the tests"
   let verbose_all_tests=1
fi

# Run tests

# Drive all the pins HIGH
for testName in ${x8Tests[@]}; do

  if [ $verbose == 1 ]; then  
    echo "Run $testName test"
  fi

  if [ $verbose_all_tests == 1 ]; then
    ./manufacturing-test-$testName.sh -v
  else
    ./manufacturing-test-$testName.sh
  fi

  ret=$?
  if [ $ret == "0" ]; then
    echo "$testName test passed :)"
    let pass=pass+1
  else
    echo "$testName test failed :("
    let fail=fail+1
  fi

done

echo "X8 test report:"
echo "$pass test passed"
echo "$fail test failed"

#add parsing of return value

if [ $fail == 0 ]; then
  echo "  PPPPPPPP            PPPPP                 PPPPPPPPPPPP       PPPPPPPPPPPP"
  echo "  PPP    PPPP        PPP  PPP             PPPPPPPPPPPPPP     PPPPPPPPPPPPPP"
  echo "  PPP      PPPP     PPP    PPP           PPPPP              PPPPP"
  echo "  PPP       PPPP   PPP      PPP          PPPPP              PPPPP"
  echo "  PPP      PPPP   PPP        PPP          PPPPP              PPPPP"
  echo "  PPP    PPPP    PPPPPPPPPPPPPPPP          PPPPPPPPPP         PPPPPPPPPP"
  echo "  PPPPPPPP      PPPPPPPPPPPPPPPPPP             PPPPPPPPP          PPPPPPPPP"
  echo "  PPP          PPP              PPP                 PPPPP              PPPPP"
  echo "  PPP         PPP                PPP                PPPPP              PPPPP"
  echo "  PPP        PPP                  PPP    PPPPPPPPPPPPPPP    PPPPPPPPPPPPPPP"
  echo "  PPP       PPP                    PPP   PPPPPPPPPPPPP     PPPPPPPPPPPPPP"
else
  echo "  FFFFFFFFFFFFF           FFFFF               FFF     FFF"
  echo "  FFFFFFFFFFFFF          FFF FFF              FFF     FFF"
  echo "  FFF                   FFF   FFF             FFF     FFF"
  echo "  FFF                  FFF     FFF            FFF     FFF"
  echo "  FFFFFFFFFFFFF       FFF       FFF           FFF     FFF"
  echo "  FFFFFFFFFFFFF      FFFFFFFFFFFFFFF          FFF     FFF"
  echo "  FFF               FFFFFFFFFFFFFFFFF         FFF     FFF"
  echo "  FFF              FFF             FFF        FFF     FFF"
  echo "  FFF             FFF               FFF       FFF     FFF"
  echo "  FFF            FFF                 FFF      FFF     FFFFFFFFFFFFF"
  echo "  FFF           FFF                   FFF     FFF     FFFFFFFFFFFFF"
  exit 0
fi

echo ""
echo "**************************END MANUFACTURING-TEST-X8**************************"
echo ""