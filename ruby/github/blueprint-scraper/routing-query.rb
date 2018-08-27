require "yaml"

$services = []

puts "Finding all services with routing section..."

Dir["fs-eng/*.yml"].each do |blueprint_filename|
  # puts blueprint_filename
  input_file = File.open(blueprint_filename, 'r')
  input_yml = input_file.read
  input_file.close

  blueprint = YAML::load(input_yml)
  next if blueprint['version'] == 0.3

  blueprint_name = blueprint['name']
  next if blueprint['deploy'].nil?

  systems = blueprint['deploy']
  systems.each do |system_name, services|
    services.each do |service_name, service_def|
      if service_def.has_key? 'routing'
        $services.push([blueprint_name, system_name, service_name])
      end
    end
  end
end

puts "Found #{$services.size} services with 'routing' sections:"

$services.each do |b, sys, srv|
  puts "#{b} | #{sys} | #{srv}"
end
