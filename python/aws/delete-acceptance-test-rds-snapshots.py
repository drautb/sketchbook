import json
import os
import subprocess

EB_COMMAND = "aws rds "

def shell(cmd):
  print "Executing shell cmd: " + cmd
  output = subprocess.check_output(cmd, shell=True)
  print "Cmd output: " + output
  return output

snapshots = json.loads(shell(EB_COMMAND + "describe-db-snapshots --snapshot-type manual"))["DBSnapshots"]

for s in snapshots:
  snapshot = s["DBSnapshotIdentifier"]
  if ("blueprint-deploy-testapp" in snapshot) or ("acceptance-test-app" in snapshot) or ("bpd-testapp" in snapshot):
    try:
      shell(EB_COMMAND + "delete-db-snapshot --db-snapshot-identifier " + snapshot)
      print "DELETED " + snapshot
    except subprocess.CalledProcessError as e:
      print "FAILED TO DELETE " + snapshot

print "Complete."
