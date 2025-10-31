#!/usr/bin/env python3

import json
import sys
from collections import defaultdict

def read_json_file(file_path):
    with open(file_path, 'r') as f:
        return json.load(f)

def read_site_ids(file_path):
    with open(file_path, 'r') as f:
        return [line.strip() for line in f if line.strip()]

def group_sites_by_region(sites_data, target_site_ids):
    # Create a mapping of siteId to parent_region
    site_to_region = {site['siteId']: site['parent_region']
                     for site in sites_data['sites']}

    # Group sites by region
    region_groups = defaultdict(list)
    for site_id in target_site_ids:
        if site_id in site_to_region:
            region_groups[site_to_region[site_id]].append(site_id)

    return region_groups

def print_bash_template(region, sites):
    print(f"```bash")
    print(f"ssh2hc ARIADNE-BASTION-PROD-{region.upper()}")
    sites_str = " ".join(sites)
    print(f"export sites=({sites_str})")
    print(f"```")
    # print("for site in ${sites[@]}; do")
    # print('  echo "Configuring Overrides On: $site"')
    # print('  yes yes | /apollo/env/Ariadne-Bastion/bin/ariadne-cli local-overrides -s $site signaling --set \\')
    # print('    -l ipte-span-path-info -dt aszs -d na-1 -d eu-1 \\')
    # print('    -l ipte-traffic-shift-entities -dt aszs -d na-1 -d eu-1')
    # print("done")
    print()  # Empty line between groups

def main():
    if len(sys.argv) != 3:
        print("Usage: python script.py <path_to_sites_json> <path_to_site_ids_file>")
        sys.exit(1)

    json_path = sys.argv[1]
    site_ids_path = sys.argv[2]

    try:
        # Read input files
        sites_data = read_json_file(json_path)
        target_site_ids = read_site_ids(site_ids_path)

        # Group sites by region
        region_groups = group_sites_by_region(sites_data, target_site_ids)

        # Print bash template for each group
        for region, sites in region_groups.items():
            print_bash_template(region, sites)

    except FileNotFoundError as e:
        print(f"Error: File not found - {e}")
        sys.exit(1)
    except json.JSONDecodeError:
        print("Error: Invalid JSON file")
        sys.exit(1)

if __name__ == "__main__":
    main()
