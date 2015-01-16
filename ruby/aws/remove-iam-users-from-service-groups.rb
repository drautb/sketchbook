# This purpose of this script is to help cleanup resources
# leftover from acceptance tests in AWS. It locates IAM groups
# that were created for acceptance tests, and removes users
# from them. This prepares the groups themselves to be
# deleted when we delete the cloudformation stack that
# created them.

require "aws-sdk"

ONE_WEEK = 60 * 60 * 24 * 7

@iam_client = AWS::IAM::Client.new

@groups_checked = 0
@users_deleted = 0

def handle_response(response)
  raise response[:error] unless response[:error].nil?  
end

def delete_old_iam_resources(next_token=nil)
  puts "delete_old_iam_resources. Checked #{@groups_checked} groups, deleted #{@users_deleted} users so far."

  options = {:path_prefix => "/ServiceGroups/"}
  options[:marker] = next_token unless next_token.nil?
  
  result = @iam_client.list_groups(options)
  group_list = result[:groups]

  group_list.each do |g|
    group_name = g[:group_name]
    group_id = g[:group_id]
    created = g[:create_date]

    if group_name.include? "sysps-bpd-testapp" or
      group_name.include? "acceptance-test-app" or
      group_name.include? "dynamodbtable-acceptance-test" or
      group_name.include? "blueprint-deploy-tes"

      if (Time.now - created) > ONE_WEEK
        # Delete dependent users
        group = @iam_client.get_group({:group_name => group_name})
        users = group[:users]
        users.each do |u|
          puts "\t\tDeleting user: #{u[:user_name]}"
          @iam_client.remove_user_from_group({:group_name => group_name, :user_name => u[:user_name]})

          access_keys_meta = @iam_client.list_access_keys({:user_name => u[:user_name]})[:access_key_metadata]
          access_keys_meta.each do |k|
            handle_response @iam_client.delete_access_key({:user_name => u[:user_name], :access_key_id => k[:access_key_id]})
          end
          
          handle_response @iam_client.delete_user({:user_name => u[:user_name]})
          @users_deleted += 1
        end
      end
    end

    @groups_checked += 1
  end

  # Recur on the next portion of the list
  delete_old_iam_resources(result[:marker]) unless result[:marker].nil?
end

delete_old_iam_resources
puts "Complete. Checked #{@groups_checked} groups, deleted #{@users_deleted} users."
