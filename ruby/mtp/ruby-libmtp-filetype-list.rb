require 'device/LibMTP'

$stdout.sync = true

LibMTP::connect do |device|
  puts "\nSupported file types:"
  device.supported_filetypes.sort.each do |type|
    puts "Type: #{type}, "
    puts "Description: #{LibMTP::filetype_desc(type)}\n\n"
  end
end

