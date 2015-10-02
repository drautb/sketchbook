require 'device/LibMTP'

$stdout.sync = true

LibMTP::connect do |device|
  puts "Device Friendly Name: #{device.friendly_name}"
  puts "Device Battery Level: #{device.battery_level}"
end

