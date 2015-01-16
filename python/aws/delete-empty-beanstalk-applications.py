import json
import os
import subprocess

EB_COMMAND = "aws elasticbeanstalk "

def shell(cmd):
  print "Executing shell cmd: " + cmd
  output = subprocess.check_output(cmd, shell=True)
  print "Cmd output: " + output
  return output

applications = json.loads(shell(EB_COMMAND + "describe-applications"))["Applications"]

for a in applications:
  appName = a["ApplicationName"]
  try:
    shell(EB_COMMAND + "delete-application --application-name " + appName)
    print "DELETED " + appName
  except subprocess.CalledProcessError as e:
    print "FAILED TO DELETE " + appName

print "Complete."
