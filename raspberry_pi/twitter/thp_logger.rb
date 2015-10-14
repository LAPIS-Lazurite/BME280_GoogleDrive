#! /usr/bin/ruby
# encoding: utf-8
# -*- coding: utf-8; mode: ruby -*-
# Function:
#   Lazurite Sub-GHz/Lazurite Pi Gateway Sample program
#   SerialMonitor.rb

require 'net/http'
require 'date'
require 'twitter'
##
# BP3596 API
##

class BP3596PipeApi
  @@client = Twitter::REST::Client.new do |config|
        config.consumer_key = "ここにカスタマーキーを入力してください"
        config.consumer_secret = "ここにカスタマーシークレットを入力してください"
        config.access_token = "ここにアクセストークンを入力してください"
        config.access_token_secret = "ここにアクセストークンシークレットを入力してください。"
  end
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
  def BinaryMonitor(raw)
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

	# 
	print(sprintf("PANID=0x%04X, rxAddr=0x%04X, txAddr=0x%04X, DATA:: ",myPanid, rxAddr, txAddr))

	for num in 9..len-2 do
	  print(raw[num].unpack("H*")[0]," ")
    end
	print("\n")
  end
  def THP_logger(raw)
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
            message = sprintf("現在の日時は%s、温度は%.2f℃、湿度は%.2f%%、気圧は%dhPaです。",t,csv[1],csv[2],csv[3].to_i)
            p message
            begin
                @@client.update(message)
            rescue Twitter::Error => e
                p e
            end
        else
            unsupported_format(raw)
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

  # Loop until it receives a SIGINT
  while finish_flag==0 do
    # Read device
    recv_buf = bp_api.read_device(bp3596_fp)
    if recv_buf == -1
      next
    end
    # Create a transmit buffer from the receive buffer
	bp_api.THP_logger(recv_buf)
  end
  # Close the Receiving pipe
  bp3596_fp.close
end
