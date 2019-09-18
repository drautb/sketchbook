require "yaml"

bp_name_include = ARGV[0]
bp_name_exclude = ARGV[1]

bp_name_include = "^.*$" if bp_name_include.nil?

blueprint_names = []

Dir["fs-eng/*.yml"].each do |filename|
  begin
    yml = YAML.load_file(filename)
    puts filename
    name = yml["name"]

    if name != "" and name != nil  and yml["deploy"] != nil
      next if !bp_name_exclude.nil? && name =~ /#{bp_name_exclude}/
      blueprint_names << name if name =~ /#{bp_name_include}/
    end
  rescue => e
    # Don't care, skipping malformed blueprint.
  end
end

File.open("blueprint-names.txt", "w") { |f| f.puts(blueprint_names) }
