require 'device/LibMTP'

$stdout.sync = true

LibMTP::connect do |device|
  puts "\n\nFolders:"
  device.folder_list do |folder|
    puts folder['name']
  end
end

