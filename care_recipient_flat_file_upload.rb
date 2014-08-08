require 'curb'
require "json"

SERVER = "http://127.0.0.1:5000"
FLAT_FILE_UPLOAD_TOKEN = "Paste here the FlatFileUploadToken provided by eCaring."

def post_file(upload_file)
  puts "Uploading #{upload_file}..."
  c = Curl::Easy.new("#{SERVER}/flat_file_upload/care_recipient_flat_files.json")
  c.multipart_form_post = true
  c.http_post(
    Curl::PostField.content('care_recipient_flat_file[flat_file_upload_token]', FLAT_FILE_UPLOAD_TOKEN),
    Curl::PostField.file('care_recipient_flat_file[file]', upload_file)
  )
  puts "* Server response"
  puts c.body_str

  response = JSON.parse(c.body_str)
  puts "  id            : #{response['id']}"
  puts "  number of rows: #{response['rows']}"
  puts "  file size     : #{response['file_size']}"
  puts "  Logs:"
  last_log_id = nil
  response['logs'].each do |log|
    puts "    #{log['created_at']}: #{log['message']}"
    last_log_id = log['id']
  end

  while(response['completed_at'].nil?) do
    c = Curl::Easy.new("#{SERVER}/flat_file_upload/care_recipient_flat_files/#{response['id']}/log_refresh.json")
    c.multipart_form_post = true
    c.http_post(
      Curl::PostField.content('flat_file_upload_token', FLAT_FILE_UPLOAD_TOKEN),
      Curl::PostField.content('log_from', last_log_id.to_s)
    )
    response = JSON.parse(c.body_str)
    response['logs'].each do |log|
      puts "    #{log['created_at']}: #{log['message']}"
      last_log_id = log['id']
    end
  end
end

ARGV.each do |upload_file|
  post_file(upload_file)
end
