#!/usr/bin/env ruby

require "octokit"
require "git"

USERNAME = ARGV[0]
puts "Cloning all repos in '#{USERNAME}'..."

@github_client = Octokit::Client.new
@github_client.auto_paginate = true

@github_client.login = ENV['GITHUB_USERNAME']
@github_client.password = ENV['GITHUB_PASSWORD']

# Authenticate
@github_client.user

@repo_list = @github_client.organization_repositories(USERNAME)

@repo_list.map do |repo|
  if USERNAME == "fs-eng"
    if repo[:name].include? "paas" or repo[:name].include? "drautb"
    else
      puts "Skipping #{repo[:name]}"
      next
    end
  end

  puts "Cloning #{repo[:name]}"
  begin
    Git.clone(repo[:ssh_url], repo[:name])
  rescue => e
    puts "Error occurred, skipping clone."
  end
end
