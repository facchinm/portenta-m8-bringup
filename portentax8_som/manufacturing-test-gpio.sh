#!/bin/bash

verbose=0
fail=0
gpio5_val_hex=0
gpio5_dr_hex=0

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


setSpiPinsAsOutput() {
   gpio5_dr=$(/unit_tests/memtool -32 30240004 1 | grep '0x30240004:'| awk -v col=2 '{print $col}')
   if [ $verbose == 1 ]; then
      echo "GPIO5 DR: $gpio5_dr"
   fi
   gpio5_dr="$(( 0x$gpio5_dr | 0x3300 ))"
   if [ $verbose == 1 ]; then
      echo "GPIO5 DR after mask: $gpio5_dr"
   fi
   gpio5_dr_hex=$(printf "%x\n" $gpio5_dr)
   if [ $verbose == 1 ]; then
      echo "GPIO5 DR HEX after mask: $gpio5_dr_hex"
   fi
   # Set pins HIGH
   /unit_tests/memtool -32 30240004=0x$gpio5_dr_hex
}

readSpiPins() {
   gpio5_val_hex=$(/unit_tests/memtool -32 30240000 1 | grep '0x30240000:'| awk -v col=2 '{print $col}')
   if [ $verbose == 1 ]; then
      echo "GPIO5: $gpio5_val_hex"
   fi
}

setSpiPinsHigh() {
   readSpiPins
   gpio5_val="$(( 0x$gpio5_val_hex | 0x3300 ))"
   gpio5_val_hex=$(printf "%x\n" $gpio5_val)
   if [ $verbose == 1 ]; then
      echo "GPIO5 with SPI pins HIGH: $gpio5_val_hex"
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

allPins=(84 85 86 87 88 98 99 106 107 108 109 131 132 134 135 138 139 144 145 148 149 154 155 156 157 160 161 162 163 164 165 166 169 170 171 172 173 174 175 176 177 178 179 180 181 182 183 184 185 186 187 188 189 190 191 192)

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

# Set as OUTPUT
#  - GPIO5_IO8  (SPI1_MISO)
#  - GPIO5_IO9  (SPI1_SS)
#  - GPIO5_IO12 (SPI2_MISO)
#  - GPIO5_IO13 (SPI2_SS)
setSpiPinsAsOutput

setSpiPinsHigh

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

# Set GPIO5_IO8 (SPI1_MISO) LOW
regVal="$(( 0x$gpio5_val_hex & 0xFFFFFEFF ))"
regVal_hex=$(printf "%x\n" $regVal)
/unit_tests/memtool -32 30240000=0x$regVal_hex
# Send I2C command I2C_READ_PINS to tell the son to to read all the sons' pins and wait OK
if [ $verbose == 1 ]; then
   echo "Sending command to read pins status..."
fi
i2cset -f -y 2 $DTTADDRESS $I2CREADPINS c
wait_ok
/unit_tests/memtool -32 30240000=0x$gpio5_val_hex

# Set GPIO5_IO9 (SPI1_SS) LOW
regVal="$(( 0x$gpio5_dr_hex & 0xFFFFFDFF ))"
regVal_hex=$(printf "%x\n" $regVal)
/unit_tests/memtool -32 30240000=0x$regVal_hex
# Send I2C command I2C_READ_PINS to tell the son to to read all the sons' pins and wait OK
if [ $verbose == 1 ]; then
   echo "Sending command to read pins status..."
fi
i2cset -f -y 2 $DTTADDRESS $I2CREADPINS c
wait_ok
/unit_tests/memtool -32 30240000=0x$gpio5_dr_hex

# Set GPIO5_IO12 (SPI2_MISO) LOW
regVal="$(( 0x$gpio5_dr_hex & 0xFFFFEFFF ))"
regVal_hex=$(printf "%x\n" $regVal)
/unit_tests/memtool -32 30240000=0x$regVal_hex
# Send I2C command I2C_READ_PINS to tell the son to to read all the sons' pins and wait OK
if [ $verbose == 1 ]; then
   echo "Sending command to read pins status..."
fi
i2cset -f -y 2 $DTTADDRESS $I2CREADPINS c
wait_ok
/unit_tests/memtool -32 30240000=0x$gpio5_dr_hex

# Set GPIO5_IO13 (SPI2_SS) LOW
regVal="$(( 0x$gpio5_dr_hex & 0xFFFFDFFF ))"
regVal_hex=$(printf "%x\n" $regVal)
/unit_tests/memtool -32 30240000=0x$regVal_hex
# Send I2C command I2C_READ_PINS to tell the son to to read all the sons' pins and wait OK
if [ $verbose == 1 ]; then
   echo "Sending command to read pins status..."
fi
i2cset -f -y 2 $DTTADDRESS $I2CREADPINS c
wait_ok

# Restore originale GPIO5_DR
/unit_tests/memtool -32 30240004=0x$gpio5_dr_hex


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