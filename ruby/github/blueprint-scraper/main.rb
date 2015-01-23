# blueprint-scraper is a little project I started to be
# able to download the blueprint.yml file from every fs-eng
# repository.
#
# Originally, I wanted to write a converter to convert 0.3
# blueprints to the 1.0 schema. I thought having lots of
# real blueprints to use would be good.
#
# I'd like to add a simple file database to the scraper, so
# that it keeps track of the project each blueprint came
# from, what version it is, and when it was last modified.

require_relative "./scraper.rb"

scraper = BlueprintScraper::Scraper.new
scraper.scrape_blueprints

