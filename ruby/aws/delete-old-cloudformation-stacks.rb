require "aws-sdk"

ONE_WEEK = 60 * 60 * 24 * 7

@cfn_client = AWS::CloudFormation::Client.new

@stacks_checked = 0
@stacks_deleted = 0

def handle_response(response)
  raise response[:error] unless response[:error].nil?
end

def delete_old_stacks(next_token=nil)
  puts "\ndelete_old_stacks: DELETED: #{@stacks_deleted} CHECKED: #{@stacks_checked}\n"
  
  options = {:stack_status_filter => [
               "CREATE_COMPLETE",
               "ROLLBACK_COMPLETE",
               "DELETE_FAILED",
               "UPDATE_COMPLETE"
             ]}
  options[:next_token] = next_token unless next_token.nil?

  result = @cfn_client.list_stacks(options)
  
  stack_list = result[:stack_summaries]

  stack_list.each do |s|
    stack_name = s[:stack_name]
    stack_id = s[:stack_id]
    
    puts "Checking stack #{stack_name}..."
    @stacks_checked += 1
    
    if stack_name.include? "sysps-bpd-testapp" or
      stack_name.include? "acceptance-test-app" or
      stack_name.include? "blueprint-deploy-testapp" or
      stack_name.include? "paas-sps-ebworker"
      created = s[:creation_time]
      if (Time.now - created) > ONE_WEEK
        puts "Deleting stack #{stack_name}. (ID: #{stack_id})"
        puts "\tCREATED: #{created}"
        handle_response @cfn_client.delete_stack({:stack_name => stack_id})
        @stacks_deleted += 1
      end
    end
  end

  puts "Checking :next_token for another round: #{result[:next_token]}"
  delete_old_stacks(result[:next_token]) unless result[:next_token].nil?
  puts "No :next_token, exiting..."
end

delete_old_stacks
puts "Done. Deleted #{@stacks_deleted}/#{@stacks_checked} stacks."
