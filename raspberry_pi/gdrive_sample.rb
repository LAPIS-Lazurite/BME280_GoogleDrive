#! /usr/bin/ruby
# -*- coding: utf-8; mode: ruby -*-
# Function:
#   Lazurite Sub-GHz/Lazurite Pi Gateway Sample program
#   SerialMonitor.rb


$:.unshift File.dirname(__FILE__)
require "gdrive.rb"

def handle_get_url(client_id, redirect_url)
  puts "Please open URL with Browser, and Accept use GoogleDrive."
  puts "After accept, you get code for OAuth."
  puts "\n#{Gdrive.create_oauth2_url(client_id, redirect_url)}\n"
end

def hendle_get_json(client_id, client_secret, redirect_url)
  print "Enter OAuth code: "
  code = gets.chomp
  $code = code

  json = Gdrive.get_oauth2_token(client_id, client_secret, redirect_url, code)
  puts "You get 「refresh_token」."
  puts "#{json}"
end

def handle_write(client_id, client_secret)
  print "Enter RefreshToken: "
  refresh_token = gets.chomp
  $refresh_token_tmp = refresh_token

  session = Gdrive.create_session(client_id, client_secret, refresh_token)

  print "Enter SpreadSheet name: "
  name = gets.chomp
  $name = name

  sheet = session.open_spreadsheet(name)

  # print "Enter worksheet index: "
  # index = gets.chomp.to_i
  index = 0 # 0固定

  print "Enter write data (delimiter 「,」): "
  data = gets.chomp.split(",")

  if sheet.write_line(index, data)
    puts "write sccess!"
  else
    puts "write failed..."
  end
end

def create_googleDriveMonitor
    system("rm GoogleDriveMonitor_tmp.rb")
    open("GoogleDriveMonitor.rb","r") do |f|
		f.readlines.each do |line|
			open("GoogleDriveMonitor_tmp.rb","a") do |outf|
				if /\$client_id =/ =~ line
					outf.write("$client_id = ")
					outf.write("\"")
					outf.write($client_id_tmp)
					outf.write("\"")
					outf.write("\n")
				elsif /\$client_secret =/ =~ line
					outf.write("$client_secret = ")
					outf.write("\"")
					outf.write($client_secret_tmp)
					outf.write("\"")
					outf.write("\n")
				elsif /\$oauth2_code =/ =~ line
					outf.write("$oauth2_code = ")
					outf.write("\"")
					outf.write($code)
					outf.write("\"")
					outf.write("\n")
				elsif /\$refresh_token =/ =~ line
					outf.write("$refresh_token = ")
					outf.write("\"")
					outf.write($refresh_token_tmp)
					outf.write("\"")
					outf.write("\n")
				elsif /THP_logger/ =~ line
					outf.write(line.gsub("THP_logger",$name))
			    else
					outf.write(line)
				end
			end
		end
	end
end

if __FILE__ == $0

  print "Enter ClientID: "
  client_id = gets.chomp
  $client_id_tmp = client_id
  print "Enter ClientSecret: "
  client_secret = gets.chomp
  $client_secret_tmp = client_secret
# print "Enter RedirectURL: "
# redirect_url = gets.chomp
  redirect_url = "urn:ietf:wg:oauth:2.0:oob"
# $redirect_url_tmp = redirect_rul

  loop do

    puts "\n"
    puts "1 Get OAuth2 code get URL."
    puts "2 Get RefreshToken JSON."
    puts "3 write 1 line to spredsheet"
	puts "4 create GoogleDriveMonitor"
    puts "5 execute GoogleDriveMonitor"
    puts "6 quit"
    puts "\n"

    print "Enter select number: "
    num = gets.chomp

    begin
      case num
      when "1" then handle_get_url(client_id, redirect_url)
      when "2" then hendle_get_json(client_id, client_secret, redirect_url)
      when "3" then handle_write(client_id, client_secret)
      when "4" then create_googleDriveMonitor
      when "5" then 
	  	system("sudo insmod /home/pi/driver/sub-ghz/DRV_802154.ko ch=33")
	  	system("ruby1.9.3 GoogleDriveMonitor_tmp.rb")
      when "6" then
	  	system("sudo rmmod DRV_802154")
	  	exit(true)
      else puts "Invalid select..."
      end
    rescue => e
      puts "Error occred...(#{e})"
      puts e.backtrace
    end

  end

end
