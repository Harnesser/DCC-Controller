#! /usr/bin/env python
from time import sleep
import serial

link = serial.Serial('/dev/ttyUSB0', baudrate=9600, timeout=2)
print "Link:", link
for i in xrange(10):
    print "www"
    link.write("A001:F:S5")
    sleep(10)
    link.write("A001:B:S6")
    sleep(14)
