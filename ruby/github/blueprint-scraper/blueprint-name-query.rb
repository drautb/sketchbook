require "yaml"

$repo_name = ""

bp_name = ARGV[0]
puts "Finding blueprint with name '#{bp_name}'..."

Dir["fs-eng/*.yml"].each do |blueprint_filename|
  # puts blueprint_filename
  input_file = File.open(blueprint_filename, 'r')
  input_yml = input_file.read
  input_file.close

  begin
    blueprint = YAML::load(input_yml)
    next if blueprint['version'] == 0.3

    blueprint_name = blueprint['name']
    if blueprint_name == bp_name then
      puts "Found #{blueprint_filename}"
      break
    end
  rescue => e
    # Don't care, skipping malformed blueprint.
  end
end
