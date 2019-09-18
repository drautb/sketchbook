require "yaml"

$items = []

puts "Finding all validate types ..."

Dir["fs-eng/*.yml"].each do |blueprint_filename|
  # puts blueprint_filename
  input_file = File.open(blueprint_filename, 'r')
  input_yml = input_file.read
  input_file.close

  begin
    blueprint = YAML::load(input_yml)
    next if blueprint['version'] == 0.3

    blueprint_name = blueprint['name']
    next if blueprint['validate'].nil?

    validates = blueprint['validate']
    validates.each do |definition|
      type = definition['type']
      if !definition['tests'].nil?
        tests = definition['tests']
        next if tests.nil?
        tests.each do |test_def|
          test_type = test_def['test_type']
          next if test_type.nil?
          $items.push([blueprint_name, test_type, type])
        end
      else
        $items.push([blueprint_name, type, 'deprecated'])
      end
    end
  rescue => e
    # Don't care, skipping malformed blueprint.
  end
end

puts "Found #{$items.size} validates with types :"

validate_types = {}
$items.each do |b, t, tt|
  if validate_types[tt].nil?
    validate_types[tt] = {'count': 1, 'types': {t => {'count': 1, 'blueprints': [b]}}}
  else
    validate_types[tt][:count] += 1
    if validate_types[tt][:types][t].nil?
      validate_types[tt][:types][t] = {'count': 1, 'blueprints': [b]}
    else
      validate_types[tt][:types][t][:count] += 1
      validate_types[tt][:types][t][:blueprints].push(b)
    end
  end
end

validate_types.each do |tt, data|
  puts "#{tt}  (#{data[:count]})"
  data[:types].each do | t, tdata |
    puts "  #{t} (#{tdata[:count]})"
  end
end
