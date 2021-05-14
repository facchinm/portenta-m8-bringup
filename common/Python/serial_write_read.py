#!/usr/bin/env python3

# Arduino testing serial

import sys
import serial
from time import sleep

def print_help():
	print("Usage: %s '/dev/ttymxc0'" % sys.argv[0])

if len(sys.argv) is not 2:
	print_help()
	exit(0)

dev = sys.argv[1]
print("Using device %s" % dev)

ser = serial.Serial()
ser.baudrate = 115200
ser.port = dev
ser.timeout = 0
print(str(ser)) # Print settings

ser.open()
sleep(.5)    
ser.flushInput()        
ser.flushOutput()
tx = b'hello'
print("Writing %s" % tx)
ser.write(tx) # Write a string
sleep(1)
rx = ser.read(32)
print("Received: %s" % rx)
ser.close()
