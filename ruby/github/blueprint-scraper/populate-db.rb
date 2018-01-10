require 'pg'
require 'json'
require 'yaml'

=begin
CREATE TABLE IF NOT EXISTS blueprint (
  id SERIAL PRIMARY KEY NOT NULL,
  name TEXT NOT NULL,
  data JSONB NOT NULL,
  raw TEXT NOT NULL);

CREATE INDEX data_index ON blueprint USING gin (data);
=end

conn = PG.connect(dbname: 'blueprints_jan_08_2018')
conn.prepare('insertblueprint', 'INSERT INTO blueprint (name, data, raw) VALUES ($1, $2::jsonb, $3)')

Dir["fs-eng/*.yml"].each do |blueprint_filename|
  puts "Importing " + blueprint_filename
  input_file = File.open(blueprint_filename, 'r')
  input_yml = input_file.read
  input_file.close

  yaml_obj = YAML::load(input_yml)
  blueprint_name = yaml_obj['name']
  blueprint_name = yaml_obj['app']['name'] if blueprint_name.nil?

  output_json = JSON.dump(yaml_obj)
  conn.exec_prepared('insertblueprint', [blueprint_name, output_json, input_yml])
end
