require "yaml"

$services = []

puts "Finding all services using blueprint tags..."

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
        if service_def.has_key? 'tags'
          $services.push([
            service_def['location'],
            blueprint_name,
            system_name,
            service_name,
            service_def['tags']
          ])
        end
      end
    end
  rescue => e
    # Don't care, skipping malformed blueprint.
  end
end

puts "Found #{$services.size} services of using blueprint tags."

summary = {}
$services.each do |_, _, _, _, tags|
  tags.each do |k, v|
    summary[k] = {} if summary[k].nil?
    summary[k][v] = 0 if summary[k][v].nil?
    summary[k][v] += 1
  end
end

summary = summary.sort_by {|k, v| v.size}.reverse
summary.each do |k, vcounts|
  vcounts = vcounts.sort_by {|k, v| v}.reverse
  puts "\nTAG KEY: #{k}"
  vcounts.each do |v, count|
    printf "\t%-30s %s\n", v, count
  end
end
