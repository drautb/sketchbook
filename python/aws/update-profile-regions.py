#!/usr/bin/env python3

# Update ~/.aws/config profiles to have a default region based on the profile name
# if the profile name follows the airport code pattern

import configparser
import json
import re
import subprocess
import sys

config_file = sys.argv[1]
cookie_file = sys.argv[2]

print("Reading current config...")
config = configparser.ConfigParser()
config.read(config_file)

print(f"Config contains {len(config.sections())} profiles...")
config_changed = False
for profile in config.sections():
	site = profile.replace("profile ", "")
	if re.search("^[a-z]{3}\\d{1,3}$", site) and "region" not in config[profile]:
		url = f"https://nsm-iad.amazon.com/_search_site_mapping?site={site}"
		# print(f"Getting region for {site}")
		args = [
			"curl", 
			"-L",
			"--cookie",
			cookie_file,
			"--cookie-jar",
			cookie_file,
			url
		]
		result = subprocess.run(args, capture_output=True)

		try:
			result_data = json.loads(result.stdout)
		except:
			print("Failed to load result data")
			print(f"STDOUT: {result.stdout}")
			print(f"STDERR: {result.stderr}")

		if "external_region" in result_data:
			print(f"{site} region is {result_data['external_region']}")
			config[profile]["region"] = result_data["external_region"]
			config_changed = True

if config_changed:
	print("Writing updated config...")
	with open(config_file, "w") as configfile:
  		config.write(configfile)