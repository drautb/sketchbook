require "yaml"
require "pp"

$stdout.sync = true

class DataSet

  attr_reader :dot_three, :one_oh, :dot_three_with_deploy, :system_keys, :system_count, :service_count, :service_keys, :blueprint_names_to_migrate

  def initialize
    @dot_three = 0
    @one_oh = 0
    @dot_three_with_deploy = 0
    @system_count = 0
    @service_count = 0
    @system_keys = {}
    @service_keys = {}
    @blueprint_names_to_migrate = []
  end

  def process_blueprint(blueprint_data)
    process_version(blueprint_data)
    if is_0_3?(blueprint_data)
      process_deploy_section(blueprint_data)
      process_services_section(blueprint_data)
    end
  end

  private

  def is_0_3?(blueprint_data)
    blueprint_data["version"] == 0.3
  end

  def process_version(blueprint_data)
    version = blueprint_data["version"]
    if is_0_3?(blueprint_data)
      @dot_three += 1
    elsif version == 1.0
      @one_oh += 1
    else
      puts "\tUnknown blueprint version: #{version}"
    end
  end

  def process_deploy_section(blueprint_data)
    if blueprint_data["app"] == nil || blueprint_data["app"]["deploy"] == nil || blueprint_data["app"]["deploy"]["systems"] == nil
      return
    end

    @dot_three_with_deploy += 1
    @blueprint_names_to_migrate.push(blueprint_data["app"]["name"])
    systems = blueprint_data["app"]["deploy"]["systems"]
    systems.each do |sys_key, sys_def|
      @system_count += 1
      sys_def.each do |sub_sys_key, _|
        # @service_count += 1
        if @system_keys[sub_sys_key] == nil
          @system_keys[sub_sys_key] = 1
        else
          @system_keys[sub_sys_key] += 1
        end
      end
    end
  end

  def process_services_section(blueprint_data)
    if blueprint_data["app"] == nil || blueprint_data["app"]["services"] == nil
      return
    end

    services = blueprint_data["app"]["services"]
    services.each do |s|
      service_type = s.keys.first
      @service_count += 1
      if @service_keys[service_type] == nil
        @service_keys[service_type] = 1
      else
        @service_keys[service_type] += 1
      end
    end
  end

end

data = DataSet.new

blueprints_processed = 0
repo_count = 1378 # As of Aug 11, 2015
blueprints = Dir["/Users/drautb/GitHub/drautb/sketchbook/ruby/github/blueprint-scraper/fs-eng/*.yml"]
blueprints.each do |blueprint_file|
  puts "Processing '#{blueprint_file}'"
  b = YAML.load_file(blueprint_file)
  data.process_blueprint(b)
  blueprints_processed += 1
end

puts "\n\n"
puts "Processed #{blueprints_processed} blueprints."
percentage = (blueprints_processed / repo_count.to_f * 100).to_i
puts "#{blueprints_processed}/#{repo_count} fs-eng repos have blueprints. (#{percentage}%)"
puts "\n"
percentage = (data.dot_three / blueprints_processed.to_f * 100).to_i
puts "#{data.dot_three}/#{blueprints_processed} blueprints are 0.3. (#{percentage}%)"
percentage = (data.dot_three_with_deploy / data.dot_three.to_f * 100).to_i
puts "Of the #{data.dot_three} 0.3 blueprtints, #{data.dot_three_with_deploy} deploy systems to AWS. (#{percentage}%)"

puts "In the #{data.dot_three_with_deploy} 0.3 blueprints that deploy to AWS, there are #{data.system_count} systems containing #{data.service_count} services."

puts "\nSystem Breakdown:"
data.system_keys.sort {|a1,a2| a2[1].to_i <=> a1[1].to_i }.each do |k, v|
  puts "#{k}: #{v}"
end

puts "\nService Breakdown:"
data.service_keys.sort {|a1,a2| a2[1].to_i <=> a1[1].to_i }.each do |k, v|
  puts "#{k}: #{v}"
end

puts "\n\n"

puts "Blueprint Names to Migrate:"
puts data.blueprint_names_to_migrate.uniq
