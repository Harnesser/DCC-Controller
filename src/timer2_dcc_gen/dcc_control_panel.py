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
            style = wx.DEFAULT_FRAME_STYLE ^ ( 
                wx.RESIZE_BORDER | wx.MINIMIZE_BOX | wx.MAXIMIZE_BOX ) )
                     
        self.dcc_address = 1
        self.dcc_speed = 5
        self.dcc_forward = True
        
        self.link = SerialLink()
                
        direction_panel = self._direction_widgets()
        speed_direction = self._speed_and_direction_widgets()
        
        self.top_sizer = wx.BoxSizer(wx.VERTICAL)
        self.top_sizer.Add(speed_direction, flag=wx.ALIGN_CENTER)
        self.top_sizer.Add(direction_panel, flag=wx.ALIGN_CENTER)
        self.SetSizer(self.top_sizer)
        
        # Status Bar
        self.statusbar = self.CreateStatusBar()
        self.Fit()
        
    def _speed_and_direction_widgets(self):
        
        addr_label = wx.StaticText(self, -1, "Address:")
        
        self.addr_entry = wx.TextCtrl(self, -1, "%d" % self.dcc_address)
        self.Bind(wx.EVT_TEXT, self.OnAddressChange, self.addr_entry)
        
        speed_label = wx.StaticText(self, -1, "Speed:")
        self.speed_entry = wx.TextCtrl(self, -1, "%d" % self.dcc_speed)
        self.Bind(wx.EVT_TEXT, self.OnSpeedChange, self.speed_entry)

        # Grid sizer for these
        sizer = wx.GridSizer(rows=2, cols=2, hgap=5, vgap=5 )
        label_align = wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL
        sizer.Add(addr_label, flag=label_align)
        sizer.Add(self.addr_entry, 0, 0)
        sizer.Add(speed_label, flag=label_align)
        sizer.Add(self.speed_entry, 0, 0)
        
        return sizer        

        
    def OnAddressChange(self, evt):
        self.dcc_address = int( '0'+self.addr_entry.GetValue() )

    def OnSpeedChange(self, evt):
        self.dcc_speed = int( '0'+self.speed_entry.GetValue() )
        self._dcc_command()
        
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
	    self.dcc_forward = True
	    self._dcc_command()
	    
    def OnStop(self, evt):
	    self._dcc_command(stop=True)
        
    def _dcc_command(self, stop=False):
        speed = 0 if stop else self.dcc_speed
        dir_txt = "Forward" if self.dcc_forward else "Reverse"
        
        txt = 'Sent: %s Address=%03d, Speed=%d' % (
            dir_txt, self.dcc_address, speed)
        self.statusbar.SetStatusText(txt)
        self.link.dcc_command(self.dcc_address, self.dcc_forward, speed)
        
if __name__ == '__main__':
    app = wx.PySimpleApp()
    frame = TopFrame(None)
    frame.Show(True)
    app.MainLoop()




