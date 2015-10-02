require 'device/LibMTP'

$stdout.sync = true

LibMTP::connect do |device|
  puts "\nTracks:"
  device.track_list do |track|
    puts track['name']
  end
end

