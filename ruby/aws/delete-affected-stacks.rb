require "aws-sdk"
require "json"

cfn_client = AWS::CloudFormation::Client.new
stacks = JSON.parse(File.read("./affected_stacks.json"))
n = 0

stacks.each do |s|
  stack_id = s["stack_id"]
  puts "Deleting stack: #{stack_id}"
  cfn_client.delete_stack({:stack_name => stack_id})
  n += 1
end

puts "Done. #{n} stacks deleted."
