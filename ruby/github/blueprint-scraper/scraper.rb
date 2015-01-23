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

      @repo_list = fetch_repositories
      puts "Found #{@repo_list.length} repositories in #{FAMILY_SEARCH_ORGANIZATION}."

      FileUtils.mkdir_p(FAMILY_SEARCH_ORGANIZATION)
      @repo_list.each do |repo_full_name|
        scrape_blueprint(repo_full_name)
      end

      puts "Done."
    end
    
    private

    def fetch_repositories
      repos = @github_client.organization_repositories(FAMILY_SEARCH_ORGANIZATION)
      repos.map { |repo| repo[:full_name] }
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
