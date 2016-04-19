#!/usr/bin/env ruby

# This script will setup GitHub's branch protection so that we can't accidentally
# git push -f to master.

require "octokit"
require "git"

ORG_USERNAME = "fs-eng"
MAIN_BRANCH = "master"

@github_client = Octokit::Client.new
@github_client.auto_paginate = true

@github_client.login = ENV['GITHUB_USERNAME']
@github_client.password = ENV['GITHUB_PASSWORD']

# Authenticate
@github_client.user

@repo_list = @github_client.organization_repositories(ORG_USERNAME)

@repo_list.each do |repo|
  if repo[:name] =~ /^[Pp]aa[Ss]-/
    puts "Protecting #{repo[:name]}..."

    begin
      @github_client.protect_branch("#{ORG_USERNAME}/#{repo[:name]}", MAIN_BRANCH)
    rescue => e
      puts "There was an error: #{e}"
    end
  end
end
