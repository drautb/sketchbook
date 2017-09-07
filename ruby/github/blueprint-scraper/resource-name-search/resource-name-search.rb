require "yaml"
require "pp"
require "./data_set.rb"

$stdout.sync = true

data = DataSet.new

blueprints_processed = 0
blueprints = Dir["/Users/drautb/GitHub/drautb/sketchbook/ruby/github/blueprint-scraper/fs-eng/*.yml"]

# Known invalid blueprints, manually verified no resource_names.
blacklist = [
  "/Users/drautb/GitHub/drautb/sketchbook/ruby/github/blueprint-scraper/fs-eng/cds-browser-blueprint.yml",
  "/Users/drautb/GitHub/drautb/sketchbook/ruby/github/blueprint-scraper/fs-eng/ipres-s3datastore-prod-blueprint.yml",
  "/Users/drautb/GitHub/drautb/sketchbook/ruby/github/blueprint-scraper/fs-eng/mcd-paas-tutorial-blueprint.yml",
  "/Users/drautb/GitHub/drautb/sketchbook/ruby/github/blueprint-scraper/fs-eng/simeki-paas-tutorial-blueprint.yml",
  "/Users/drautb/GitHub/drautb/sketchbook/ruby/github/blueprint-scraper/fs-eng/tf-cassandra-spark-blueprint.yml"
]

blueprints.each do |blueprint_file|
  if blacklist.include?(blueprint_file)
    puts "Skipping bad blueprint #{blueprint_file}"
    next
  end

  puts "Processing '#{blueprint_file}'"
  b = YAML.load_file(blueprint_file)
  data.process_blueprint(blueprint_file, b)
  blueprints_processed += 1
end

puts "Processed #{blueprints_processed} blueprints. Saving results to disk."

File.open("/Users/drautb/GitHub/drautb/sketchbook/ruby/github/blueprint-scraper/resource-name-search/results.out", "wb") do |file|
   Marshal.dump(data, file)
end
