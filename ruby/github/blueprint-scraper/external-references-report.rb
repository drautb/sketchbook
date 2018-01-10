require "yaml"
require "json"

require 'net/http'

# refs['blueprint']['system']['service'] = {
#   :references_me => [
#     [blueprint, system, service],
#     [blueprint, system, service]
#   ]
#   :references = [
#     [blueprint, system, service],
#     [blueprint, system, serivce]
#   ]
# }

$refs = {}

def ensure_entry_exists(blueprint, system, service)
  $refs[blueprint] = {} if $refs[blueprint].nil?
  $refs[blueprint][system] = {} if $refs[blueprint][system].nil?
  if $refs[blueprint][system][service].nil?
    $refs[blueprint][system][service] = { :references_me => [], :references => [] }
  end
end

def update_references(bp, sys, srv, ref_name)
  ref_name = ref_name.sub("URI://", "")
  ref_bp, ref_sys, ref_srv = ref_name.split("/")

  $refs[bp][sys][srv][:references].push([ref_bp, ref_sys, ref_srv])

  ensure_entry_exists(ref_bp, ref_sys, ref_srv)
  $refs[ref_bp][ref_sys][ref_srv][:references_me].push([bp, sys, srv])
end

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
      next if service_def['references'].nil?

      service_refs = service_def['references']

      service_refs.each do |ref|
        ref_name = ref if ref.is_a? String
        ref_name = ref.keys.first if ref.is_a? Hash

        next unless ref_name.start_with? "URI://"

        ensure_entry_exists(blueprint_name, system_name, service_name)
        update_references(blueprint_name, system_name, service_name, ref_name)
      end
    end
  end
end

# File.open("references.json", "w") do |f|
#   f.write(JSON.dump($refs))
# end

puts "Unique blueprints involved: #{$refs.size}"

total_services = []
$refs.each do |blueprint_name, systems|
  systems.each do |system_name, services|
    services.each do |service_name, ref_map|
      total_services.push([blueprint_name, system_name, service_name])
    end
  end
end

puts "Unique services involved:   #{total_services.size}"

puts "\n\nChecking Deployed Services..."

missing = {}
found = 0
total_services.each do |s|
  bp, sys, srv = s

  uri = URI("http://#{ENV['DSS_HOST']}/ds/services/?blueprint=#{bp}&system=#{sys}&service=#{srv}")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{ENV['FSSESSIONID']}"

  res = Net::HTTP.start(uri.hostname, uri.port) {|http|
    http.request(req)
  }

  if res.is_a?(Net::HTTPSuccess)
    response = JSON.parse(res.body)
    if response['services'].size == 1
      found += 1
    else
      puts "MULTIPLE MATCHED: #{res.body}"
      found += 1
    end
  elsif res.is_a?(Net::HTTPNotFound)
    missing[bp] = {} if missing[bp].nil?
    missing[bp][sys] = [] if missing[bp][sys].nil?
    missing[bp][sys].push(srv)
  else
    puts res
    puts res.body
    raise "Unknown!"
  end
end

puts "Found #{found} in DSS."

puts "\nMISSING:"
missing.each do |bp, systems|
  puts bp
  systems.each do |sys_name, services|
    puts "  #{sys_name}"
    services.each do |s|
      puts "    #{s}"
    end
  end
end

puts "\nBlueprints: #{missing.size}"
