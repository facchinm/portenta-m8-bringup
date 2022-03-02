#!/bin/bash

verbose=0
fail=0

echo ""
echo "*************************START MANUFACTURING-TEST-GPIO*************************"
echo ""

if [[ $1 == "-v" ]]; then
   echo "Verbose mode"
   let verbose=1
fi

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

lsmod | grep x8h7_drv
if [ $? == 1 ]; then
   if [ $verbose == 1 ]; then 
      echo "Loading driver module..."
   fi
   insmod /home/root/extra/x8h7_drv.ko
fi

#lsmod | grep x8h7i_gpio
#if [ $? == 1 ]; then
#if [ $verbose == 1 ]; then echo "Loading gpio module..." fi
#insmod /home/root/extra/x8h7_gpio.ko
#elif [ $verbose == 1 ]; then echo "Gpio module already loaded"
#fi

lsmod | grep i2c
if [ $? == 1 ]; then
   if [ $verbose == 1 ]; then 
      echo "Loading i2c module..."
   fi
   modprobe i2c-dev
fi

DTTADDRESS=0x0A

I2CREADPINS=0x0A
I2CALLINPUT=0x0B
I2CCLEARCOUNTERS=0x0C

allPins=(84 85 86 87 88 106 107 108 109 131 132 134 135 136 138 139 140 144 145 148 149 156 157 160 161 162 163 164 165 166 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192)

# Send I2C command I2C_ALL_INPUT (0x0B) to tell the son to put all the pins in INPUT and wait OK
if [ $verbose == 1 ]; then
   echo "Sending command to set all pins in input..."
fi
i2cset -f -y 2 $DTTADDRESS $I2CALLINPUT c
wait_ok

# Send I2C command I2C_CLEAR_COUNTERS (0x0C) to tell the son to reset the transitions counters and wait OK
if [ $verbose == 1 ]; then
   echo "Sending command to clear all counters..."
fi
i2cset -f -y 2 $DTTADDRESS $I2CCLEARCOUNTERS c
wait_ok

# Reset IOMUX configuration for SPI1 pins
# 0x303301F4 = IOMUXC_SW_MUX_CTL_PAD_ECSPI1_SCLK
/unit_tests/memtool -32 303301F4=00000005
# 0x303301F8 = IOMUXC_SW_MUX_CTL_PAD_ECSPI1_MOSI
/unit_tests/memtool -32 303301F8=00000005
# 0x303301FC = IOMUXC_SW_MUX_CTL_PAD_ECSPI1_MISO
/unit_tests/memtool -32 303301FC=00000005

# Reset IOMUX configuration for SPI2 pins
# 0x30330204 = IOMUXC_SW_MUX_CTL_PAD_ECSPI2_SCLK
/unit_tests/memtool -32 30330204=00000005
# 0x30330208 = IOMUXC_SW_MUX_CTL_PAD_ECSPI2_MOSI
/unit_tests/memtool -32 30330208=00000005
# 0x3033020C = IOMUXC_SW_MUX_CTL_PAD_ECSPI2_MISO
/unit_tests/memtool -32 3033020C=00000005

# Reset IOMUX configuration for I2C4 pins
# 0x3033022C = IOMUXC_SW_MUX_CTL_PAD_I2C4_SCL
/unit_tests/memtool -32 3033022C=0x00000005
# 0x30330230 = IOMUXC_SW_MUX_CTL_PAD_I2C4_SDA
/unit_tests/memtool -32 30330230=0x00000005

# Drive all the pins HIGH
for n in ${allPins[@]}; do
   if [ $verbose == 1 ]; then
      echo "Driving $n pin HIGH"
   fi
   echo $n > /sys/class/gpio/export
   echo out > /sys/class/gpio/gpio$n/direction
   echo 1 > /sys/class/gpio/gpio$n/value
done

if [ $verbose == 1 ]; then
   echo "Configuring SPI pins with memtool..."
fi

# Set pins LOW, one at a time
for n in ${allPins[@]}; do
   # Drive nth pin LOW
   if [ $verbose == 1 ]; then
      echo "Driving $n pin LOW"
   fi
   echo 0 > /sys/class/gpio/gpio$n/value

   # Send I2C command I2C_READ_PINS to tell the son to to read all the sons' pins and wait OK
   if [ $verbose == 1 ]; then
      echo "Sending command to read pins status..."
   fi
   i2cset -f -y 2 $DTTADDRESS $I2CREADPINS c
   wait_ok
   echo 1 > /sys/class/gpio/gpio$n/value
done

# Unexport the gpios
if [ $verbose == 1 ]; then
   echo "Unexport all pins"
fi
for n in ${allPins[@]}; do
   echo $n > /sys/class/gpio/unexport
done

echo ""
echo "**************************END MANUFACTURING-TEST-GPIO**************************"
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