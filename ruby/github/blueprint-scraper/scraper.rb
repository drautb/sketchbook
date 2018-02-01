require "base64"
require "fileutils"
require "octokit"

module BlueprintScraper
  class Scraper

    FAMILY_SEARCH_ORGANIZATION = "fs-eng"
    BLUEPRINT_FILE = "blueprint.yml"

    def initialize
      @github_client = Octokit::Client.new
      @github_client.auto_paginate = true
      login
    end

    def scrape_blueprints
      puts "Starting blueprint scraper..."

      time_start = Time.now

      puts "Removing all existing blueprints in #{FAMILY_SEARCH_ORGANIZATION} directory..."
      FileUtils.rm_rf(FAMILY_SEARCH_ORGANIZATION)

      @repo_list = fetch_repositories
      puts "Found #{@repo_list.length} repositories in #{FAMILY_SEARCH_ORGANIZATION}."

      FileUtils.mkdir_p(FAMILY_SEARCH_ORGANIZATION)
      @repo_list.each do |repo|
        scrape_blueprint(repo[:full_name])
      end

      time_end = Time.now

      puts "Done. Finished in #{time_end - time_start} seconds."
    end

    def list_repositories
      puts "Listing repositories...\n\n"

      @repo_list = fetch_repositories
      @repo_list.map { |r| r[:name] }.sort.each do |repo_name|
        puts "#{repo_name}"
      end

      puts "\nDone. #{@repo_list.length} repositories found."
    end

    def list_contributors(repo_name)
      @github_client.contribs("#{FAMILY_SEARCH_ORGANIZATION}/#{repo_name}")
    end

    private

    def fetch_repositories
      @github_client.organization_repositories(FAMILY_SEARCH_ORGANIZATION)
    end

    def scrape_blueprint(repo_full_name)
      puts "Scraping #{BLUEPRINT_FILE} from #{repo_full_name}."
      filename = "#{repo_full_name}-#{BLUEPRINT_FILE}"
      begin
        file_metadata = @github_client.content(repo_full_name, :path => BLUEPRINT_FILE)
        content = Base64.decode64(file_metadata[:content])
        File.open(filename, "w") do |f|
          puts "Writing #{filename}."
          f.write(content)
        end
      rescue Octokit::NotFound => e
        puts "\t#{BLUEPRINT_FILE} not found in #{filename}."
      end
    end

    def login
      @github_client.login = get_username
      @github_client.password = get_password

      # Authenticate
      @github_client.user
    end

    def get_username
      print "GitHub Username: "
      username = gets.chomp
      username
    end

    def get_password
      print "Password: "
      system "stty -echo"
      password = gets.chomp
      system "stty echo"
      puts
      password
    end

  end
end
