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

  json = Gdrive.get_oauth2_token(client_id, client_secret, redirect_url, code)
  puts "You get 「refresh_token」."
  puts "#{json}"
end

def handle_write(client_id, client_secret)
  print "Enter RefreshToken: "
  refresh_token = gets.chomp

  session = Gdrive.create_session(client_id, client_secret, refresh_token)

  print "Enter SpreadSheet name: "
  name = gets.chomp

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

if __FILE__ == $0

  print "Enter ClientID: "
  client_id = gets.chomp
  print "Enter ClientSecret: "
  client_secret = gets.chomp
  print "Enter RedirectURL: "
  redirect_url = gets.chomp

  loop do

    puts "\n"
    puts "1 Get OAuth2 code get URL."
    puts "2 Get RefreshToken JSON."
    puts "3 write 1 line to spredsheet"
    puts "4 quit"
    puts "\n"

    print "Enter select number: "
    num = gets.chomp

    begin
      case num
      when "1" then handle_get_url(client_id, redirect_url)
      when "2" then hendle_get_json(client_id, client_secret, redirect_url)
      when "3" then handle_write(client_id, client_secret)
      when "4" then exit(true)
      else puts "Invalid select..."
      end
    rescue => e
      puts "Error occred...(#{e})"
      puts e.backtrace
    end

  end

end
