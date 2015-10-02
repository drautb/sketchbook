#!/usr/bin/env ruby

require_relative "./blueprint-scraper/scraper.rb"

TEAM_MEMBERS = ["drautb", "kinsersh", "woodstock3368", "hartleybd", "buckml", "jfree-fs", "barclaysteven", "barrettford", "npaxton", "egglestonbd", "vernonfuller", "nterry", "thayneharmon", "jamesdnelson", "mlindsey58", "wdurhamh", "MatthewHarker", "cjkirk09", "wahkara", "jmillard7"]

repos_to_keep = IO.readlines('repos-to-keep.txt')

scraper = BlueprintScraper::Scraper.new

File.open("repos-with-contribs.txt", "w") do |f|
  repos_to_keep.each do |repo_name|
    repo_name.strip!

    contributors = scraper.list_contributors(repo_name)

    contrib_list = []
    contributors.each do |c|
      contrib_list.push(c[:login])
    end

    contrib_list = contrib_list.keep_if { |c| TEAM_MEMBERS.include? c }

    f.write("#{repo_name}\t#{contrib_list.join(',')}\n")
  end
end
