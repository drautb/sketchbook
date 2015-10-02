#!/usr/bin/env ruby

require 'aws-sdk'

$stdout.sync = true

WORKFLOW_INPUT = <<INPUT
[
  {
    "blueprintName": "drautb-test",
    "syspsWorkflowId": "drautb-test-manual-error",
    "systemName": "dev",
    "serviceName": "world",
    "buildNumber": "build-1",
    "buildSnapshotUrl": "someurl",
    "definition": {
      "type": "hello_world",
      "location": "development-fh5-useast1-primary-1",
      "name": "BennyBoy"
    },
    "triggerURL": "asdf",
    "triggerRev": "commithash"
  }
]
INPUT

@swf_client = Aws::SWF::Client.new(region: 'us-east-1')

def start_execution(workflow_id)
  puts "Starting execution '#{workflow_id}'..."

  @swf_client.start_workflow_execution({:domain => "paas-sps-dev",
                                       :workflow_id => workflow_id,
                                       :workflow_type => {:name => "HelloWorldProvisioner.check", :version => "0.0.2-dev-drautb"},
                                       :input => WORKFLOW_INPUT})
end

start_execution("drautb-test-manual-error-hello-world")
