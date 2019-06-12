require "yaml"

$services = []

service_type = ARGV[0]
puts "Finding all services with resource names of type '#{service_type}'..."

Dir["fs-eng/*.yml"].each do |blueprint_filename|
  # puts blueprint_filename
  input_file = File.open(blueprint_filename, 'r')
  input_yml = input_file.read
  input_file.close

  begin
    blueprint = YAML::load(input_yml)
    next if blueprint['version'] == 0.3

    blueprint_name = blueprint['name']
    next if blueprint['deploy'].nil?

    systems = blueprint['deploy']
    systems.each do |system_name, services|
      services.each do |service_name, service_def|
        if service_def.has_key? 'resource_name' and service_def['type'].start_with? service_type
          $services.push([blueprint_name, system_name, service_name, service_def['resource_name']])
        end
      end
    end
  rescue
    # Don't care
  end
end

puts "Found #{$services.size} services of type '#{service_type}' with resource_name:"

$services.each do |b, sys, srv, rn|
  puts "#{b} | #{sys} | #{srv} | #{rn}"
end
