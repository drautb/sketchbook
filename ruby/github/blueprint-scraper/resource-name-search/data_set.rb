class DataSet

  attr_reader :dot_three, :one_oh, :unknown_versions, :one_oh_with_deploy, :system_count, :service_count, :resource_name_count, :resource_names, :resource_names_hier, :unfinished_migrations

  def initialize
    @dot_three = 0
    @one_oh = 0
    @unknown_versions = []
    @one_oh_with_deploy = 0
    @system_count = 0
    @service_count = 0
    @resource_name_count = 0
    @resource_names = {}
    @resource_names_hier = {}
    @unfinished_migrations = {}
  end

  def process_blueprint(filename, blueprint_data)
    return unless blueprint_data
    process_version(filename, blueprint_data)
    if is_1_0?(blueprint_data)
      process_deploy_section(filename, blueprint_data)
    end
  end

  private

  def is_0_3?(blueprint_data)
    blueprint_data["version"] == 0.3
  end

  def is_1_0?(blueprint_data)
    blueprint_data["version"] == 1.0
  end

  def process_version(filename, blueprint_data)
    version = blueprint_data["version"]
    if is_0_3?(blueprint_data)
      @dot_three += 1
    elsif is_1_0?(blueprint_data)
      @one_oh += 1
    else
      @unknown_versions << filename
      puts "\tUnknown blueprint version: #{version} (#{filename}"
    end
  end

  def process_deploy_section(filename, blueprint_data)
    if blueprint_data["deploy"] == nil
      return
    end

    @one_oh_with_deploy += 1
    systems = blueprint_data["deploy"]

    systems.each do |sys_key, sys_def|
      # puts "\tProcessing system: #{sys_key}\n"
      @system_count += 1
      sys_def.each do |srv_key, srv_def|
        # puts "\t\tProcessing service: #{srv_key}\n"
        @service_count += 1

        type = srv_def["type"]
        location = srv_def["location"]
        resource_name = srv_def["resource_name"]

        if resource_name != nil
          @resource_name_count += 1

          key = [location, type, resource_name]
          @resource_names[key] = [] if @resource_names[key] == nil
          value = {
            "filename" => filename,
            "blueprint" => blueprint_data["name"],
            "system" => sys_key,
            "service" => srv_key
          }
          @resource_names[key] << value

          @resource_names_hier[location] = {} if @resource_names_hier[location] == nil
          @resource_names_hier[location][type] = {} if @resource_names_hier[location][type] == nil
          @resource_names_hier[location][type][resource_name] = [] if @resource_names_hier[location][type][resource_name] == nil
          @resource_names_hier[location][type][resource_name] << value

          if resource_name.start_with? "0.3"
            @unfinished_migrations[location] = {} if @unfinished_migrations[location] == nil
            @unfinished_migrations[location][type] = [] if @unfinished_migrations[location][type] == nil
            @unfinished_migrations[location][type] << value
          end

        end
      end
    end
  end

  def marshal_dump
    [@dot_three, @one_oh, @unknown_versions, @one_oh_with_deploy, @system_count, @service_count, @resource_name_count, @resource_names, @resource_names_hier, @unfinished_migrations]
  end

  def marshal_load array
    @dot_three, @one_oh, @unknown_versions, @one_oh_with_deploy, @system_count, @service_count, @resource_name_count, @resource_names, @resource_names_hier, @unfinished_migrations = array
  end

end
