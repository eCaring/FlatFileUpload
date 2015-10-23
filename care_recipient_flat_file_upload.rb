#!/usr/bin/env ruby

require 'optparse'
require 'curb'
require 'json'

def post_file(upload_file, options = {})
  verbose = options[:verbose]
  debug = options[:debug]
  test_mode = 0

  puts "Uploading #{upload_file}..." if verbose
  if options[:test_mode]
    puts "Test mode!!!" if verbose
    test_mode = 1
  end

  c = Curl::Easy.new("#{options[:server]}/flat_file_upload/care_recipient_flat_files.json")
  c.multipart_form_post = true
  c.http_post(
    Curl::PostField.content('care_recipient_flat_file[flat_file_upload_token]', options[:token]),
    Curl::PostField.content('care_recipient_flat_file[test_mode]', test_mode.to_s),
    Curl::PostField.file('care_recipient_flat_file[file]', upload_file)
  )
  puts "* Server response" if debug
  puts c.body_str if debug

  response = JSON.parse(c.body_str)
  puts "  id            : #{response['id']}" if debug
  puts "  number of rows: #{response['rows']}" if debug
  puts "  file size     : #{response['file_size']}" if debug
  puts "  Logs:" if verbose
  last_log_id = nil
  response['logs'].each do |log|
    puts "    #{log['created_at']}: #{log['message']}" if verbose
    last_log_id = log['id']
  end

  while(response['completed_at'].nil?) do
    c = Curl::Easy.new("#{options[:server]}/flat_file_upload/care_recipient_flat_files/#{response['id']}/log_refresh.json")
    c.multipart_form_post = true
    c.http_post(
      Curl::PostField.content('flat_file_upload_token', options[:token]),
      Curl::PostField.content('log_from', last_log_id.to_s)
    )
    response = JSON.parse(c.body_str)
    response['logs'].each do |log|
      puts "    #{log['created_at']}: #{log['message']}" if verbose
      last_log_id = log['id']
    end
  end
end


options = {
  config: "care_recipient_flat_file_upload.json",
  debug: false,
  verbose: false,
  test_mode: false
}


opt_parser = OptionParser.new do |opts|
  opts.banner = "Usage: care_recipient_flat_file_upload.rb [options] csv_files\nOptions:"

  opts.on("-cCONFIG_FILE", "--config=CONFIG_FILE", "Config file to use (default: #{options[:config]}") do |c|
    options[:config] = c
  end

  opts.on("-sSERVER", "--server=SERVER", "Server to connect to (if not in config file). (default: https://secure.ecaring.com)") do |n|
    options[:server] = n
  end

  opts.on("-tTOKEN", "--token=TOKEN", "FlatFileUploadToken provided by eCaring (if not in config file).") do |t|
    options[:token] = t
  end

  opts.on("-d", "--debug", "Debug mode") do
    options[:debug] = true
  end

  opts.on("-v", "--verbose", "Verbose") do
    options[:verbose] = true
  end

  opts.on("--test_mode", "Process CSV without recording data (test mode)") do
    options[:test_mode] = true
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end

opt_parser.parse!

p File.expand_path(__FILE__)

config_files = [
  options[:config],          # Search the current directory or specified path
  File.join(File.dirname(File.expand_path(__FILE__)), options[:config]), # Search where this file resides
  File.join("~/", options[:config])   # Search the home directory
]

config_files.each do |config_file|
  if File.exist?(config_file)
    config = JSON.parse(File.read(config_file))
    config.each do |k,v|
      options[k.to_sym] ||= v
    end
    break
  end
end

options[:server] ||= "https://secure.ecaring.com"

if options[:debug]
  puts "options=#{(options).inspect}"
  puts "ARGV=#{(ARGV).inspect}"
end

if ARGV.empty?
  puts "Missing csv files"
  puts opt_parser
else
  ARGV.each do |upload_file|
    post_file(upload_file, options)
  end
end
