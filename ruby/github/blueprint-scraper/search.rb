require "yaml"
require "pp"

blueprints = Dir["/Users/drautb/GitHub/sketchbook/ruby/github/blueprint-scraper/fs-eng/*.yml"]
blueprints.each do |blueprint_file|
  b = YAML.load_file(blueprint_file)
  break if b["version"] == 0.3

  pp b
  systems = b["deploy"]
  break if systems.nil?

  systems.each do |sys|
    puts "SYS: #{sys}"
    sys.each do |service|
      puts "Checking service: #{service}"
      if service["type"] == "s3bucket"
        puts "FOUND 1.0 S3 in #{blueprint_file}"
      end
    end
  end
end
