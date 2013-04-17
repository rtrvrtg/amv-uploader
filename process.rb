#!/usr/bin/env ruby

require 'logger'
require_relative 'amv-uploader-class'
require_relative 'config'

# quit unless our script gets two command line arguments
unless ARGV.length == 1
  puts "Dude, not the right number of arguments."
  puts "Usage: ruby process.rb \"path to video file.mov\""
  exit
end

upl = AmvUploader.new({ :src => ARGV[0] })
upl.logger(Logger.new(STDOUT))

url = upl.process('MP4Renderer', 'AwsUploader', $AWSSettings)
puts url
