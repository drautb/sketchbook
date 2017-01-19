require "aws-sdk"
require "json"

region = "us-east-1"
account = "TODO"

cfn_client = Aws::CloudFormation::Client.new(:region => region, :profile => account)
iam_client = Aws::IAM::Client.new(:region => region, :profile => account)

stacks = [
]

stacks.each do |s|
  begin
    # role_name = cfn_client.describe_stack_resource({:stack_name => s, :logical_resource_id => "beanstalkRole"}).stack_resource_detail.physical_resource_id
    # policies = iam_client.list_role_policies({:role_name => role_name}).policy_names
    # policies.each do |p|
    #   iam_client.delete_role_policy({:role_name => role_name, :policy_name => p})
    # end

    # cfn_client.delete_stack({:stack_name => s})
    result = cfn_client.describe_stacks({:stack_name => s})
    puts "#{s}:\t#{result.data.stacks[0].stack_status}"
  rescue => e
    puts e
  end
end
