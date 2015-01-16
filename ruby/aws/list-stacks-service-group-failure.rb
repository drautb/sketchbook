# The purpose of this script is to locate all the CFN stacks
# that failed to delete due being unable to delete a nonexistent
# ServiceGroup. This occurs when the ServiceGroups were manually
# deleted, rather than managed by the CFN.

require "aws-sdk"
require "json"

@cfn_client = AWS::CloudFormation::Client.new

@affected_stacks = []
@checked = 0

def retry_on_error(retry_error_classes, max_retries = 1, &block)
  (0..max_retries).each do |i|
    begin
      break block.call
    rescue *retry_error_classes => e
      raise e if i == max_retries
      sleep_time = 2 ** i
      warn("Encountered #{e.class.name} #{e}, will retry the operation in #{sleep_time} second(s).")
      sleep(sleep_time)
    end
  end
end

def stack_is_affected?(stack)
  stack_name = stack[:stack_name]

  stack_events = []
  retry_on_error([AWS::CloudFormation::Errors::Throttling], 10) do
    stack_events = @cfn_client.describe_stack_events({:stack_name => stack_name})[:stack_events]
  end
    
  most_recent_event = stack_events[0]
  puts "Checking most recent event: #{most_recent_event}"
  
  if most_recent_event[:resource_status_reason] =~ /The following resource\(s\) failed to delete:.*ServiceGroup.*/
    puts "\tStack IS affected"
    return true
  end

  puts "\tStack is NOT affected"
  return false
end

def investigate_stacks(next_token=nil)
  puts "Investigating stack failure reasons, checked #{@checked} so far, found #{@affected_stacks.length}."

  options = {
    :stack_status_filter => ["DELETE_FAILED"]
  }
  options[:next_token] = next_token unless next_token.nil?

  response = nil
  retry_on_error([AWS::CloudFormation::Errors::Throttling], 10) do
    response = @cfn_client.list_stacks(options)
  end
  stacks = response[:stack_summaries]

  stacks.each do |s|
    @affected_stacks.push({:stack_name => s[:stack_name], :stack_id => s[:stack_id]}) if stack_is_affected?(s)
    @checked += 1
  end
  
  investigate_stacks(response[:next_token]) unless response[:next_token].nil?
end

investigate_stacks
File.write('./affected_stacks.json', @affected_stacks.to_json)
puts "Complete. Affected stacks have been written to 'affected_stacks.json'"
