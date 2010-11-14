#! /usr/bin/env python
""" 
    A GUI program control the train.
"""
import os
import sys

import wx
import serial

class SerialLink(object):

    link = None
    
    def __init__(self):
        self.connect()
            
    def connect(self):
        try:         
            self.link = serial.Serial('/dev/ttyUSB0', baudrate=9600,
                timeout=2)
        except serial.serialutil.SerialException:
            pass       

    def dcc_command(self, dcc_address, dcc_forward, dcc_speed ):
    
        dir_str = 'F' if dcc_forward else 'B'
        self.link.write("A%03d:%s:S%d" % ( dcc_address, dir_str, dcc_speed ) )


class TopFrame(wx.Frame):
    
    def __init__(self, parent ):
        wx.Frame.__init__(self, parent, -1, 
            "Train Controller",
            size=(400,400) )
                     
        self.dcc_address = 1
        self.dcc_speed = 5
        self.dcc_forward = True
        
        direction_panel = self._direction_widgets()
        
        self.top_sizer = wx.BoxSizer(wx.VERTICAL)
        self.top_sizer.Add(direction_panel)
        
        self.SetSizer(self.top_sizer)
        
        self.link = SerialLink()
        
        
    def _direction_widgets(self):
        """ Forward, reverse and emergency stop controls"""

        # Back button     
        back_btn = wx.Button(self, -1, "<")
        self.Bind(wx.EVT_BUTTON, self.OnReverse, back_btn)
        
        # Stop Button
        stop_btn = wx.Button(self, -1, "Stop")
        self.Bind(wx.EVT_BUTTON, self.OnStop, stop_btn)
        
        # Forward button
        forward_btn = wx.Button(self, -1, ">")
        self.Bind(wx.EVT_BUTTON, self.OnForward, forward_btn)
                
        box = wx.StaticBox(self, -1, "Go:")
        sizer = wx.StaticBoxSizer(box, wx.HORIZONTAL)
        sizer.Add(back_btn, 0, wx.ALL, 2)
        sizer.Add(stop_btn, 0, wx.ALL, 2)
        sizer.Add(forward_btn, 0, wx.ALL, 2)
        
        return sizer
        
    def OnReverse(self, evt ):
	    self.dcc_forward = False
	    self._dcc_command()
	    
    def OnForward(self, evt ):
	    self.dcc_forward = False
	    self._dcc_command()
	    
    def OnStop(self, evt):
	    self.dcc_speed = 0
	    self._dcc_command()
        
    def _dcc_command(self):
        self.link.dcc_command(self.dcc_address, self.dcc_forward, self.dcc_speed)
        
if __name__ == '__main__':
    app = wx.PySimpleApp()
    frame = TopFrame(None)
    frame.Show(True)
    app.MainLoop()




