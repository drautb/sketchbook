# Simple script intended to discover which lambda functions in an
# account were provisioned via CloudFormation.

import boto3

client = boto3.client('lambda')

lambda_arns = []

response = {}
while True:
  if 'NextMarker' in response:
    response = client.list_functions(Marker=response['NextMarker'])
  else:
    response = client.list_functions()

  print("Found {} lambda functions...".format(len(response['Functions'])))
  for f in response['Functions']:
    lambda_arns.append(f['FunctionArn'])

  if 'NextMarker' not in response:
    break

print("Total Lambda Count: {}".format(len(lambda_arns)))

print("Looking for CloudFormation tags on each lambda...")

cfn_arns = []
for arn in lambda_arns:
  response = client.list_tags(Resource=arn)

  for tag_key, tag_value in response['Tags'].items():
    if tag_key.startswith('aws:cloudformation'):
      print(arn)
      cfn_arns.append(arn)

print("Found {} functions with CloudFormation tags.".format(len(cfn_arns)))

