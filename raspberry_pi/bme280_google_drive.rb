#! /usr/bin/ruby
# -*- coding: utf-8; mode: ruby -*-
# Function:
#   Lazurite Sub-GHz/Lazurite Pi Gateway Sample program
#   SerialMonitor.rb
require 'LazGem'
require 'google_drive'

laz = LazGem::Device.new


# Google Drive Initializin
session = GoogleDrive::Session.from_config("client_id.json")
ws = session.spreadsheet_by_key("mysheet").worksheets[0]

# Halt process when CTRL+C is pushed.
finish_flag=0
Signal.trap(:INT){
	finish_flag=1
}
# open device deriver
# 
# LAZURITE.open(ch=36,panid=0xabcd,pwr=20,rate=100),mode=2)
# parameter
#  ch:		frequency 24-61. 36 is in default
#  panid:	pan id
#  pwr:		tx power
#  rate:	bit rate  50 or 100
#  pwr:		tx power  1 or 20
#  mode:	must be 2
laz.init()
laz.begin(36,0xABCD,100,20)
print(sprintf("myAddress=0x%04x\n",laz.getMyAddress()))
laz.rxEnable()

# printing header of receiving log
print(sprintf("time\t\t\t\trxPanid\trxAddr\ttxAddr\trssi\tpayload\n"))
print(sprintf("------------------------------------------------------------------------------------------\n"))

# main routine
while finish_flag == 0 do
	if laz.available() <= 0
		next
	end
	rcv = laz.read()
	data = rcv["payload"].split(",")
	# printing data
	#p rcv
	print(sprintf("rx_time= %s\trx_nsec=%d\trssi=%d %s\n",Time.at(rcv["sec"]),rcv["nsec"],rcv["rssi"],rcv["payload"]));
	ws[ws.num_rows+1,1]=Time.at(rcv["sec"])
	ws[ws.num_rows,2]=rcv["nsec"]
	ws[ws.num_rows,3]=rcv["rx_panid"]
	ws[ws.num_rows,4]=rcv["rx_addr"]
	ws[ws.num_rows,5]=rcv["tx_addr"]
	ws[ws.num_rows,6]=rcv["rssi"]
	ws[ws.num_rows,7]=data[0]
	ws[ws.num_rows,8]=data[1]
	ws[ws.num_rows,9]=data[2]
	ws[ws.num_rows,10]=data[3]
	ws.save
end

# finishing process
laz.remove()


