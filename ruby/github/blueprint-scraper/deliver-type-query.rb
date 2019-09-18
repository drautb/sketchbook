require "yaml"

$items = []

puts "Finding all deliver types ..."

Dir["fs-eng/*.yml"].each do |blueprint_filename|
  # puts blueprint_filename
  input_file = File.open(blueprint_filename, 'r')
  input_yml = input_file.read
  input_file.close

  begin
    blueprint = YAML::load(input_yml)
    next if blueprint['version'] == 0.3

    blueprint_name = blueprint['name']
    next if blueprint['deliver'].nil?

    deliver = blueprint['deliver']
    deliver.each do |definition|
      if !definition['deploy_order'].nil?
        deploy_order = definition['deploy_order']
        deploy_order.each do |order_def|
          $items.push([blueprint_name, order_def['type']])
        end
      end
    end
  rescue => e
    # Don't care, skipping malformed blueprint.
  end
end

puts "Found #{$items.size} deliver with types :"

$items.each do |b, t|
  puts "#{b} | #{t}"
end
