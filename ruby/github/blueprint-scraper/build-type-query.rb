require "yaml"

$items = {}

puts "Finding all build types ..."

Dir["fs-eng/*.yml"].each do |blueprint_filename|
  # puts blueprint_filename
  input_file = File.open(blueprint_filename, 'r')
  input_yml = input_file.read
  input_file.close

  begin
    blueprint = YAML::load(input_yml)
    next if blueprint['version'] == 0.3

    blueprint_name = blueprint['name']
    next if blueprint['build'].nil?

    builds = blueprint['build']
    builds.each do |definition|
      type = definition['type']
      next if type.nil?
      if $items[type].nil?
        $items[type] = {'count': 1, 'blueprints':[blueprint_name]}
      else
        $items[type][:count] += 1
        $items[type][:blueprints].push(blueprint_name)
      end
    end
  rescue => e
    # Don't care, skipping malformed blueprint.
  end
end

puts "Found interesting builds with types :"

samples = []
$items.sort_by{ |type, data| [data[:count], type] }.each do |type, data|
  next if type === 'npm' || type === 'bundler' || type === 'ecplugin' || type === 'debrpm'
  puts sprintf('%4d | %s', data[:count], type)
  samples.push(data[:blueprints][rand(data[:blueprints].size)])
end

puts "\nHere are some random samples of blueprints :"
samples.each do |b|
  puts "#{b}"
end
