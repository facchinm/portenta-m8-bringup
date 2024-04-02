#!/bin/bash

verbose=1

echo ""
echo "*************************START MANUFACTURING-TEST-GPIO*************************"
echo ""

if [ "$1" = "-v" ]; then
   echo "Verbose mode"
   verbose=1
fi

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

allPins=(84 85 86 87 88 106 107 108 131 132 134 135 136 138 139 140 144 145 148 149 156 157 160 161 162 163 164 165 166 169 170 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192)

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

for n in ${allPins[@]}; do
   if [ $n != $X8_START ] && [ $n != $X8_STOP ]; then
      if [ $verbose == 1 ]; then
         echo "Driving $n pin LOW"
      fi
      
      echo 0 > /sys/class/gpio/gpio$X8_START/value
      echo 0 > /sys/class/gpio/gpio$n/value
      sleep 0.001

      stopStatus=0

      if [ $verbose == 1 ]; then
         echo "Waiting stop"
      fi
      while true; do
         stopStatus=$(cat /sys/class/gpio/gpio$X8_STOP/value)
         if [ $verbose == 1 ]; then
            echo $stopStatus
         fi
         currentTime=$(date +%s)

         # Check the condition
         if [ $stopStatus -eq 0 ] ; then
            break
         fi
         if [ $((currentTime - startTime)) -ge 300 ]; then
            echo 1 > /sys/class/gpio/gpio$X8_START/value
            echo "MISSING ACK" > /dev/ttymxc1
            echo > /dev/ttymxc1
            echo > /dev/ttymxc1
            exit 1
         fi
      done

      while true; do
         sleep 0.001
         stopStatus=$(cat /sys/class/gpio/gpio$X8_STOP/value)

         # Get the current time
         currentTime=$(date +%s)

         if [ $stopStatus -eq 0 ] ; then
            break
         fi
         if [ $((currentTime - startTime)) -ge 5000 ]; then
            echo 1 > /sys/class/gpio/gpio$X8_START/value
            echo "MISSING STOP" > /dev/ttymxc1
            echo > /dev/ttymxc1
            echo > /dev/ttymxc1
            exit 1
         fi
      done
      echo 1 > /sys/class/gpio/gpio$n/value
   fi
done

echo 1 > /sys/class/gpio/gpio$X8_START/value

# Unexport the gpios
if [ $verbose == 1 ]; then
   echo Unexport all pins
fi
for n in ${allPins[@]}; do
   echo $n > /sys/class/gpio/unexport
done

echo 
echo "**************************END MANUFACTURING-TEST-GPIO**************************"
echo 

echo "PASS"
echo 
echo 
exit 0
