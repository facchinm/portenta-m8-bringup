#!/usr/bin/env python3
#
# Arduino Lora modem python source code
#
# Tested with:
# Python 3.8.5
# pyserial-3.4
# lora modem fw 1.2.1
# lora gateway 

import logging
import serial
import time
import queue

from at_protocol import ATProtocol

### Class definition
class modemLora(ATProtocol):

    TERMINATOR = b'\r'

    loraBand = {
        "AS923": 0,
        "AU915": 1, 
        "EU868": 5,
        "KR920": 6,
        "IN865": 7,
        "US915": 8,
        "US915_HYBRID": 9
    }

    loraRfMode = {
        "RFO": 0,
        "PABOOST": 1
    }

    loraMode = {
        "ABP": 0,
        "OTAA": 1
    }

    rfProperty = {
        "APP_EUI": "+APPEUI=",
        "APP_KEY": "+APPKEY=",
        "DEV_EUI": "+DEVEUI=",
        "DEV_ADDR": "+DEVADDR=",
        "NWKS_KEY": "+NWKSKEY=",
        "NWK_ID": "+IDNWK=",
        "APPS_KEY": "+APPSKEY="
    }

    loraClass = {
        "CLASS_A": 'A',
        "CLASS_B": 'B',
        "CLASS_C": 'C'
    }

    def __init__(self):
        logging.debug("Method __init__ called")
        super(modemLora, self).__init__()
        self.event_responses = queue.Queue()
        self._awaiting_response_for = None

    def connection_made(self, transport):
        logging.debug("Method connection_made called")
        super(modemLora, self).connection_made(transport)
        # Put here code to move gpio to wake up modem
        time.sleep(0.3) # Waiting for modem to became alive
        self.transport.serial.reset_input_buffer() # Flush input data written by modem during startup

    def handle_event(self, event):
        """Handle events and command responses starting with '+...'"""
        if event.startswith('+OK') and self._awaiting_response_for.endswith('AT'):
            self.event_responses.put(event.encode())
        elif event.startswith('+OK=') and self._awaiting_response_for.startswith('AT+DEV?'):
            resp = event[4:4 + 7]
            self.event_responses.put(resp.encode())
        elif event.startswith('+OK=') and self._awaiting_response_for.startswith('AT+VER?'):
            resp = event[4:4 + 5]
            self.event_responses.put(resp.encode())
        elif event.startswith('+OK=') and self._awaiting_response_for.startswith('AT+DEVEUI?'):
            resp = event[4:4 + 5]
            self.event_responses.put(resp.encode())
        elif event.startswith('+ERR'):
            logging.error("Modem error!")
            self.event_responses.put(event.encode())
        elif event.startswith('+RRBDRES') and self._awaiting_response_for.startswith('AT+JRBD'):
            rev = event[9:9 + 12]
            mac = ':'.join('{:02X}'.format(ord(x)) for x in rev.decode('hex')[::-1])
            self.event_responses.put(mac)
        else:
            logging.warning('unhandled event: {!r}'.format(event))
            self.event_responses.put(event.encode()) # If we don't put we fall into timeout error on self.event_responses.get()

    def command_with_event_response(self, command, timeout=5):
        """Send a command that responds with '+...' line"""
        logging.debug("Sending command %s with response +..." % command)
        with self.lock:  # Ensure that just one thread is sending commands at once
            self._awaiting_response_for = command
            self.transport.write(command.encode(self.ENCODING, self.UNICODE_HANDLING) + self.TERMINATOR)
            response = self.event_responses.get(timeout=timeout)
            self._awaiting_response_for = None
            return response

    # - - - example commands

    def ping(self):
        return self.command_with_event_response("AT")

    def deviceVersion(self):
        return self.command_with_event_response("AT+DEV?")

    def firmwareVersion(self):
        return self.command_with_event_response("AT+VER?")

    def deviceEUI(self):
        return self.command_with_event_response("AT+DEVEUI?")

    def configureBand(self, band):
        value = self.loraBand(band)
        return self.command_with_event_response("AT+BAND=" + value)

    def changeMode(self, mode):
        value = self.loraMode(mode)
        return self.command_with_event_response("AT+MODE=" + mode)

    def changeProperty(self, what, value):
        propertyCmd = self.rfProperty(what)
        return self.command_with_event_response(propertyCmd + value)

    def join(self, timeout):
        return self.command_with_event_response("+JOIN", timeout)

    def joinOTAA(self, appEui, appKey, devEui=None):
        print("Changing mode to %s: %s" % (self.loraMode.OTAA, self.changeMode(self.loraMode.OTAA))
        print("Changing property %s to %s: %s" % ("APP_EUI", appEui, self.changeProperty("APP_EUI", appEui))
        print("Changing property %s to %s: %s" % ("APP_KEY", appKey, self.changeProperty("APP_KEY", appKey))
        if devEui is not None:
            print("Changing property %s to %s: %s" % ("DEV_EUI", devEui, self.changeProperty("DEV_EUI", devEui))
        self.join(60) # Timeout of 1 minute to connect

### End class definition

### Main program
if __name__ == '__main__':
    logging.basicConfig(filename='modemLora.log', level=logging.DEBUG)
    logging.info("Started script for lora modem testing")

    # Obtained during first registration of the device
    SECRET_APP_EUI=None
    SECRET_APP_KEY=None 

    ser = serial.Serial()
    ser.baudrate = 19200
    ser.port = '/dev/ttymxc3'
    ser.bytesize = 8
    ser.parity = 'N'
    ser.stopbits = 2
    ser.timeout = 1
    logging.debug("Configured serial port with:\n\r%s" % str(ser))
    logging.debug("Opening serial port")
    ser.open() # Open serial port
    with serial.threaded.ReaderThread(ser, modemLora) as lora_module:
        print("Pinging modem: %s" % lora_module.ping())
        print("Device version: %s" % lora_module.deviceVersion())
        print("Firmware version: %s" % lora_module.firmwareVersion())
        print("Device EUI: %s" % lora_module.deviceEUI())
        print("Setting band %s: %s" % (str(band), lora_module.configureBand("EU868")))
        lora_module.joinOTAA(SECRET_APP_EUI, SECRET_APP_KEY)
### End Main program
