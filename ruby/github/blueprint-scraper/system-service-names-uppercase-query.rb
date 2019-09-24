require "yaml"

$systems = []
$services = []

puts "Finding any systems and services names with upper-case..."

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
      $systems.push([blueprint_name, system_name]) if system_name =~ /[A-Z]/

      services.each do |service_name, service_def|
        $services.push([blueprint_name, system_name, service_name]) if service_name =~ /[A-Z]/
      end
    end
  rescue => e
    # Don't care, skipping malformed blueprint.
  end
end

puts ""
puts "Found the following services with upper-case..."
$services.each do |blueprint, sys, srv|
  puts "#{blueprint} | #{sys} | #{srv}"
end

puts ""
puts "Found the following systems with upper-case..."
$systems.each do |blueprint, sys|
  puts "#{blueprint} | #{sys}"
end
