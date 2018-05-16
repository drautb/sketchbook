require "yaml"

Dir["fs-webdev/*.yml"].each do |blueprint_filename|
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
      next if service_def['binding_sets'].nil?
      service_def['binding_sets'].each do |reg_name, binding_sets_list|
        binding_sets_list.each do |binding_set|
          next if binding_set['bindings'].nil?
          binding_set['bindings'].each do |binding_name, binding|
            if binding.has_key? 'type' and
               binding['type'] === 'Alias v1_0' and
               not binding['http_headers'].nil?
              puts "Found Alias binding with http_headers in #{blueprint_name}, #{reg_name}, #{binding_name}"
            end
          end
        end
      end
    end
  end
end


