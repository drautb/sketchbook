require "yaml"
require "set"

$sites = {}

Dir["fs-eng/*.yml"].each do |blueprint_filename|
  input_file = File.open(blueprint_filename, 'r')
  input_yml = input_file.read
  input_file.close

  begin
    blueprint = YAML::load(input_yml)
  rescue Psych::SyntaxError => msg
    puts "#{blueprint_filename}: #{msg}"
    next
  end

  next if blueprint['version'] == 0.3

  blueprint_name = blueprint['name']
  next if blueprint['deploy'].nil?

  systems = blueprint['deploy']
  systems.each do |system_name, services|
    services.each do |service_name, service_def|
      next if service_def['binding_sets'].nil?
      service_def['binding_sets'].each do |reg_name, binding_sets_list|
        binding_sets_list.each do |binding_set|
          next if binding_set['sites'].nil?
          binding_set['sites'].each do |site|
            $sites[site] = [] if $sites[site].nil?
            $sites[site].push("#{blueprint_filename}: #{blueprint_name}/#{system_name}/#{service_name} - #{service_def['location']}")
          end
        end
      end
    end
  end
end

# https://almtools.ldschurch.org/fhconfluence/display/ARCH/Approved+Blueprint+Binding+Set+Site+Names
canoncical_sites = [
  "prod",
  "beta",
  "integ",
  "staging",
  "dev",
  "training"
]

puts "The following sites are found in blueprints:"
$sites.each do |site, _|
  puts site
end

puts "\nUsers of non-canonical sites according to https://almtools.ldschurch.org/fhconfluence/display/ARCH/Approved+Blueprint+Binding+Set+Site+Names"

$sites.each do |site, clients|
  next if canoncical_sites.include? site

  puts "#{site}:"
  clients.each do |c|
    puts "    #{c}"
  end
end


