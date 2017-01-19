require "splunk-sdk-ruby"
require "net/http"

def connect_to_splunk
  config = {
    scheme: :https,
    host: ENV['SPLUNK_HOST'],
    port: ENV['SPLUNK_PORT'],
    username: ENV['SPLUNK_USERNAME'],
    password: ENV['SPLUNK_PASSWORD'],
    namespace: Splunk::namespace(sharing: "app", app: "fs-paas")
  }

  begin
    Splunk::connect(config)
  rescue Errno::ETIMEDOUT
    raise SplunkTimeoutError.new("Timed out initial connection to splunk!")
  end
end

puts connect_to_splunk
