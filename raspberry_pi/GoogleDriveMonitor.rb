#! /usr/bin/ruby
# -*- coding: utf-8; mode: ruby -*-
# Copyright (c) <year> <copyright holders>
 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Function:
#   Lazurite Sub-GHz/Lazurite Pi Gateway Sample program
#   GoogleDriveMonitor.rb

require 'net/http'
require 'date'
require './gdrive.rb'

$client_id = "782385752123-loh1cu4n63vf7i92166kgpvm89pntk8n.apps.googleusercontent.com"
$client_secret = "IlOR_UHyznpioFAB6qcDh3r6"
$oauth2_code ="4/p3NUMgrMkEEdLjUzrY-aku97RSZIsKWZT4Ykx9hn0ks"
$refresh_token = "1/joRC2IsKVmqDky0_EgijEK4GNvmKyOEZqXfL8ThxAXpIgOrJDtdun6zK6XiATCKT"

#JSON:
#{
#  "access_token" : "ya29.qgG3r6gUQPPeUMJ9D0VqHMnrb8oZQ8AvBkFzCMgSMvIqN9_S2iHoNtVOOtzVLiAx1xEj-vKth19a3Q",
#  "token_type" : "Bearer",
#  "expires_in" : 3600,
#  "refresh_token" : "1/joRC2IsKVmqDky0_EgijEK4GNvmKyOEZqXfL8ThxAXpIgOrJDtdun6zK6XiATCKT"
#}


##
# BP3596 API
##
class BP3596PipeApi
  ##
  # func   : Read the data from the receiving pipe
  # input  : Receive pipe fp
  # return : Receive data
  ##
  def read_device(fp)
    # Data reception wait (timeout = 100ms)
    ret = select([fp], nil, nil, 0.1)

    # Reads the size of the received data
    len = fp.read(2)
    if ((len == "") || (len == nil)) then # read result is empty
      return -1
    end
    size =  len.unpack("S*")[0]

    # The received data is read
    recv_buf = fp.read(size)
    if ((recv_buf == "") || (recv_buf == nil)) then # read result is empty
      return -1
	end

    return recv_buf
  end
  def print_raw(raw)
	fc = raw.unpack("H*")
	len = raw.length
	print(len,"bytes: ",fc,"\r\n")
  end
  def print_raw2(raw)
    len = raw.length
    header = raw.unpack("H4")[0]

	# unsupported format
	if header != "21a8" then
	  unsupported_format(raw)
	  return
	end

	# supported format
    seq = raw[2].unpack("H2")[0]

	# PANID
    myPanid = raw[3..4].unpack("S*")[0]

	# RX Address
	rxAddr = raw[5..6].unpack("S*")[0]

	# TX Address
	txAddr = raw[7..8].unpack("S*")[0]

	# convert receiving text
	str_buf = raw[9..len-2].unpack("Z*")[0]

	# get current time
	t = Time.now()

	# convert string data to csv format
	csv = str_buf.split(",");

	# check dataformat
	if csv[0] == "BME280" then
	  print(sprintf("%s, 0x%04X , 0x%04X , 0x%04X , %s\r\n",t, myPanid,rxAddr,txAddr,csv))
	  begin
	    $session = Gdrive.create_session($client_id, $client_secret, $refresh_token)
   	    $sheet = $session.open_spreadsheet("THP_logger")
	    $sheet.write_line(0, [t,myPanid,rxAddr,txAddr,csv[0],csv[1],csv[2],csv[3]]) 
	  rescue Gdrive::Error => e
	    p e
          end
	else
	  print(sprintf("%s, 0x%04X , 0x%04X , 0x%04X , %s\r\n",t, myPanid,rxAddr,txAddr,str_buf))
	end

  end

  # printing unsupported format
  def unsupported_format(raw)
    data = raw.unpack("H*")
	print("unsupported format::",data,"\n")
  end
end

##
# Main function
##
class MainFunction
  ### Variable definition
  bp3596_dev  = "/dev/bp3596" # Receiving pipe
  finish_flag = 0             # Finish flag

  # Process at the time of SIGINT Receiving
  Signal.trap(:INT){
    finish_flag=1
  }

  # Open the Receiving pipe
  bp3596_fp = open(bp3596_dev, "rb")

  bp_api = BP3596PipeApi.new

  #initializing google drive
#  begin
#    $session = Gdrive.create_session($client_id, $client_secret, $refresh_token)
#    $sheet = $session.open_spreadsheet("monitor")
#  rescue Gdrive::Error => e
#    print("google drive initializing error\r\n")
#    p e
#    exit
#  end

  # Loop until it receives a SIGINT
  while finish_flag==0 do
    # Read device
    recv_buf = bp_api.read_device(bp3596_fp)
    if recv_buf == -1
      next
    end
    # Create a transmit buffer from the receive buffer
	bp_api.print_raw2(recv_buf)
  end
  # Close the Receiving pipe
  bp3596_fp.close
end
