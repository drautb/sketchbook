require "yaml"

$services = []

service_type = "s3"
puts "Finding all S3 services with unknown elements..."

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
        if service_def.has_key? 'type' and service_def['type'] == service_type
          $services.push([blueprint_name, system_name, service_name, service_def])
        end
      end
    end
  rescue => e
    # Don't care, skipping malformed blueprint.
  end
end

puts "Found #{$services.size} services of type '#{service_type}':"

recognized_keys = ['location', 'type', 'resource_name', 'private', 'custom_permissions', 'approved_consumers']

$services.each do |bp, sys, srv, service_def|
  unrecognized_keys = service_def.keys - recognized_keys
  puts unrecognized_keys
end

