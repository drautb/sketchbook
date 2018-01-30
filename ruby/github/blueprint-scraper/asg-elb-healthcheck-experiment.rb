# Prerequisites:
#
# 1) Run the blueprint scraper to download all fs-eng blueprints.
# 2) Download our experiments.yml file into the same directory as this script.

require "yaml"

experiments_file = File.open('experiments.yml', 'r');
experiments = YAML::load(experiments_file.read)
experiments_file.close

asg_exp = {}
experiments['experiments'].each do |exp|
  unless exp['asgUseElbHealthCheck'].nil?
    asg_exp = exp['asgUseElbHealthCheck']['blueprints']
  end
end

not_in_exp = []

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
      next unless service_def['type'] =~ /.*eanstalk.*/
      next if service_def['autoscale_options'].nil?
      next if service_def['autoscale_options']['health_check_grace_period'].nil?

      if asg_exp[blueprint_name].nil? or !asg_exp[blueprint_name].include? system_name
        not_in_exp.push "#{blueprint_name} | #{system_name} | #{service_name}"
      end
    end
  end
end

puts "Found #{not_in_exp.size} services using health_check_grace_period without being in the experiment.\n\n"

not_in_exp.each do |m|
  puts "#{m}"
end
