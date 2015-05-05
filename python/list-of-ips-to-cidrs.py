#!/usr/bin/env python

from netaddr import IPAddress, cidr_merge
import sys

# Expects a list of IPs as CSV in single cmd-line arg.
ip_csv = sys.argv[1]

# Add an IPAddress object to ip_list for each address
ip_list = []
for ip_str in ip_csv.split(","):
    ip_list.append(IPAddress(ip_str))

# Condense the ip_list into CIDR blocks that exactly cover the range.
cidrs = cidr_merge(ip_list)

# Output them.
for c in cidrs:
    print c

