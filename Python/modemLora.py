#!/usr/bin/env python3
#
# Arduino Lora modem python source code
#

import logging
import serial
import time
import queue

from at_protocol import ATProtocol

### Class definition
class modemLora(ATProtocol):

    TERMINATOR = b'\r'

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
        if event.startswith('+OK') and self._awaiting_response_for.startswith('AT'):
            self.event_responses.put(event.encode())
        elif event.startswith('+OK=') and self._awaiting_response_for.startswith('AT+DEV?'):
            self.event_responses.put(event.encode())
        elif event.startswith('+OK=') and self._awaiting_response_for.startswith('AT+VER?'):
            self.event_responses.put(event.encode())
        elif event.startswith('+ERR'):
            logging.error("Modem error!")
            self.event_responses.put(event.encode())
        elif event.startswith('+RRBDRES') and self._awaiting_response_for.startswith('AT+JRBD'):
            rev = event[9:9 + 12]
            mac = ':'.join('{:02X}'.format(ord(x)) for x in rev.decode('hex')[::-1])
            self.event_responses.put(mac)
        else:
            logging.warning('unhandled event: {!r}'.format(event))

    def command_with_event_response(self, command):
        """Send a command that responds with '+...' line"""
        logging.debug("Sending command %s with response +..." % command)
        with self.lock:  # ensure that just one thread is sending commands at once
            self._awaiting_response_for = command
            self.transport.write(command.encode(self.ENCODING, self.UNICODE_HANDLING) + self.TERMINATOR)
            response = self.event_responses.get()
            self._awaiting_response_for = None
            return response

    # - - - example commands

    def ping(self):
        return self.command_with_event_response("AT")

    def deviceVersion(self):
        return self.command_with_event_response("AT+DEV?")

    def firmwareVersion(self):
        return self.command_with_event_response("AT+VER?")

### End class definition

### Main program
if __name__ == '__main__':
    logging.basicConfig(filename='modemLora.log', level=logging.DEBUG)
    logging.info("Started script for lora modem testing")
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
### End Main program
