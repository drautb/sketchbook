#!/usr/bin/env python

import sys
import requests
import json

session_id = sys.argv[1]
input_file = sys.argv[2]

PLACE_REP_TO_SET_ID = {
  # Brazil
  5740: "BR-BA_Chr",
  5739: "BR-CE_Chr",
  5743: "BR-MA_Chr",
  5731: "BR-MG_Chr",
  5732: "BR-PA_Chr",
  5733: "BR-PB_Chr",
  5734: "BR-PR_Chr",
  5735: "BR-PE_Chr",
  5721: "BR-RJ_Chr",
  5722: "BR-RN_Chr",
  5723: "BR-RS_Chr",
  5726: "BR-SC_Chr",
  5727: "BR-SP_Chr",
  5728: "BR-SE_Chr",

  # Portugal
  2205: "PT-01_Chr",
  2200: "PT-02_Chr",
  2199: "PT-03_Chr",
  2202: "PT-04_Chr",
  2201: "PT-05_Chr",
  2196: "PT-06_Chr",
  2195: "PT-07_Chr",
  2198: "PT-08_Chr",
  2197: "PT-09_Chr",
  386983: "PT-18-LamD_Chr",
  2192: "PT-10_Chr",
  2194: "PT-12_Chr",
  2193: "PT-13_Chr",
  2187: "PT-14_Chr",
  2188: "PT-15_Chr",
  2189: "PT-16_Chr",
  2190: "PT-17_Chr",
  386964: "PT-17D_Chr",
  2183: "PT-18_Chr",

  # Cape Verde
  189: "CV_Chr"
}


RMS_HOST = "http://group-service.rms.records.service.prod.us-east-1.prod.fslocal.org"


def build_headers():
  return {
    "Authorization": "Bearer " + session_id,
    "FS-User-Agent-Chain": "drautb"
  }


def get_group_id(group_name):
  url = RMS_HOST + "/group/" + group_name + "/apid"
  req = requests.get(url, headers=build_headers())
  return req.text


def get_group_properties(group_id):
  url = RMS_HOST + "/group/" + group_id + "?include-properties=true"
  req = requests.get(url, headers=build_headers())
  if req.status_code != 200:
    raise RuntimeError(req.text)

  return req.json()


def extract_coverage_place_ids(group_data):
  return sum(list(map(lambda c: c["placeRepIdHierarchy"], group_data["coverages"])), [])


def get_set_id_for_group(group_data):
  coverage_place_ids = extract_coverage_place_ids(group_data)
  for pid in coverage_place_ids:
    if pid in PLACE_REP_TO_SET_ID:
      return PLACE_REP_TO_SET_ID[pid]

  sys.stderr.write("Couldn't find set id - " + str(coverage_place_ids) + " (" + group_data["groupName"] + ")\n")


input_lines = []
with open(input_file, 'r') as f:
  input_lines = f.read().strip().splitlines()


set_id_map = {}
for group_name in input_lines:
  group_id = get_group_id(group_name)
  group_data = get_group_properties(group_id)
  set_id = get_set_id_for_group(group_data)
  if set_id:
    set_id_map[group_name] = set_id

print(json.dumps(set_id_map))

