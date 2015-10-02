#!/usr/bin/env ruby

require_relative "./blueprint-scraper/scraper.rb"

# This is a script I wrote to automate the process of looking at the contributors
# for a repo, and then putting the repo on a special list if the top contributors
# are members of the PaaS team.

repos_to_filter = IO.readlines('repos-to-filter.txt')

scraper = BlueprintScraper::Scraper.new
repos_to_keep = []

repos_to_filter.each do |repo_name|
  repo_name.strip!
  puts "\n#{repo_name}"

  begin
    contributors = scraper.list_contributors(repo_name)
  rescue => e
    puts "Error: #{e}\nSkipping repo #{repo_name}.\n"
    next
  end

  contributors.each_with_index do |c, idx|
    break if idx > 7
    puts "#{idx+1}: #{c[:login]} (#{c[:contributions]})"
  end

  puts "\nKeep #{repo_name}? (y/n)"
  response = gets.chomp

  if response == "y"
    puts "Keeping #{repo_name}."
    repos_to_keep.push(repo_name)
  end
end

puts "\nFinished filter list, writing repos to disk..."
File.open("repos-to-keep.txt", "w") { |f| f.write(repos_to_keep.join("\n")) }
