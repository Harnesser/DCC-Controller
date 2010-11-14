#! /usr/bin/env python
""" Try to find the address of dad's train... """

from time import sleep

import serial

link = serial.Serial('/dev/ttyUSB0', baudrate=9600, timeout=2)

def search_address():
	for address in range(127):
		print "Address %03d" % (address)
		link.write("A%03d:F:S3" % address )
		sleep(10)
		
def tweak_timer_target():
	link.write('A001:F:S5')
	for delta in range(40):
		print "Delta %02d" % (delta)
		link.write("D%02d" % delta)
		sleep(10)
		
		
if __name__ == '__main__':
	tweak_timer_target()
