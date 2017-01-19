require "yaml"

blueprint_names = []

Dir["fs-eng/*.yml"].each do |filename|
  yml = YAML.load_file(filename)
  puts filename
  name = yml["name"]

  if name != "" and name != nil  and yml["deploy"] != nil
    blueprint_names << name
  end
end

File.open("blueprint-names.txt", "w") { |f| f.puts(blueprint_names) }
