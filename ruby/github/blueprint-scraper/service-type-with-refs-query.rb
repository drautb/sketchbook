require "yaml"

$services = []

service_type = ARGV[0]
ref_type = ARGV[1]
puts "Finding all services with type '#{service_type}' that have references to types containing #{ref_type}..."

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
        if service_def.has_key? 'type' and service_def['type'] == service_type and service_def.has_key? 'references'
          service_def['references'].each do |ref|
            if ref.start_with? 'URI'
              bits = ref.split("/")
              bp = bits[2]
              sys = bits[3]
              srv = bits[4]

              ext_file = File.open("fs-eng/#{bp}-blueprint.yml", 'r')
              ext_yml = ext_file.read
              ext_file.close

              ext_srv = ext_yml['deploy'][sys][srv]
              if ext_srv['type'].downcase.include? ref_type.downcase
                $services.push([service_def['location'], blueprint_name, system_name, service_name])
              end
            elsif services[ref].has_key? 'type' and services[ref]['type'].downcase.include? ref_type.downcase
              $services.push([service_def['location'], blueprint_name, system_name, service_name])
            end
          end
        end
      end
    end
  rescue => e
    # Don't care, skipping malformed blueprint.
  end
end

puts "Found #{$services.size} services of type '#{service_type}' that have references to service types containing '#{ref_type}':"

$services.each do |loc, b, sys, srv|
  puts "#{loc} | #{b} | #{sys} | #{srv}"
end
