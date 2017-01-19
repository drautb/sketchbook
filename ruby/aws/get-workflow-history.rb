#!/usr/bin/env ruby

require 'aws-sdk-v1'

$stdout.sync = true

swf = AWS::SimpleWorkflow.new
PROD_DOMAIN = swf.domains['TODO']

# Production FH1 Workflow
sysps_execution = AWS::SimpleWorkflow::WorkflowExecution.new(PROD_DOMAIN,
    'WorkflowID',
    'RunId')

# Development FH5 Workflow
srvps_execution = AWS::SimpleWorkflow::WorkflowExecution.new(PROD_DOMAIN,
    'WorkflowId',
    'RunId')

history_events = AWS::SimpleWorkflow::HistoryEventCollection.new(srvps_execution, {:reverse_order => true})
attributes = history_events.first.attributes

# puts attributes[:reason]
puts attributes[:details]
