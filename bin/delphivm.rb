#!/usr/bin/env ruby

begin
  $LOAD_PATH.unshift File.join(File.dirname($0), '..', 'lib')
  require 'bundler/setup'
  require 'DelphiVM'
   
  Delphivm::Runner.start(ARGV)

rescue Interrupt => e
  puts "\nQuitting..."
  puts e.backtrace.join("\n")
  exit 1
rescue Exception => e
  puts e.message
  puts e.backtrace.join("\n")
  exit 1
end
