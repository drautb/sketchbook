require_relative "./blueprint-scraper/scraper.rb"

scraper = BlueprintScraper::Scraper.new
scraper.list_repositories
