require "./data_set.rb"

DELIM_LENGTH = 100

RESULTS_FILE = "/Users/drautb/GitHub/drautb/sketchbook/ruby/github/blueprint-scraper/resource-name-search/results.out"
REPO_COUNT = 1722 # As of Sep 7, 2017
BLUEPRINTS_PROCESSED = 1071

def break_row
  puts "-" * DELIM_LENGTH
end

data = nil
File.open(RESULTS_FILE, "rb") {|f| data = Marshal.load(f)}

puts "RESOURCE NAME ANALYSIS (9/7/17)"
puts "=" * DELIM_LENGTH
puts "REPOSITORIES: #{REPO_COUNT}\tBLUEPRINTS: #{BLUEPRINTS_PROCESSED}"
break_row
puts "1.0: #{data.one_oh}\t\t\t0.3: #{data.dot_three} (ignored)"
break_row
puts "Total System Count:\t\t#{data.system_count}"
puts "Total Service Count:\t\t#{data.service_count}"
break_row
puts "Total Resource Name Count:\t#{data.resource_name_count}"
puts "Unique Resource Name Count:\t#{data.resource_names.keys.size}"
break_row
puts "Unfinished Migrations:"
data.unfinished_migrations.each do |loc, types|
  puts "  #{loc}:"
  types.each do |type, list|
    puts "    #{(type + ":").ljust(40, ".")}#{list.size}" if list != nil
    list.each do |s|
      puts "      #{s["blueprint"]}, #{s["system"]}, #{s["service"]}"
    end
  end
end
break_row
puts "Shared Resource Names:"
data.resource_names_hier.each do |loc_key, v1|
  loc_printed = false
  v1.each do |type, v2|
    type_printed = false
    v2.each do |rn, list|
      if list.size > 1
        puts "  #{loc_key}:" unless loc_printed
        loc_printed = true
        puts "    #{type}:" unless type_printed
        type_printed = true
        puts "      #{(rn + ":").ljust(60, ".")}#{list.size}"
        list.each do |s|
          puts "        #{s["blueprint"]}, #{s["system"]}, #{s["service"]}"
        end
      end
    end
  end
end
break_row
