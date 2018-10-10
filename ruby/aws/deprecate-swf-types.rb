#!/usr/bin/env ruby

require "aws-sdk-swf"

DOMAIN = "paas-sps-dev"
ACTIVITY_PREFIX = "Beanstalk"
KEEP_VERSIONS = [
  "0.0.47",
  "0.0.48",
  "0.0.49",
  "0.0.50",
  "0.0.51",
]

$swf_client = Aws::SWF::Client.new
$dep_count = 0

def deprecate_old_activities(activities)
  activities.each do |a|
    if a.activity_type.name.start_with? ACTIVITY_PREFIX and not KEEP_VERSIONS.include? a.activity_type.version
      puts "Deprecating activity type: #{a.activity_type.name}, #{a.activity_type.version}"
      $swf_client.deprecate_activity_type({
        domain: DOMAIN,
        activity_type: {
          name: a.activity_type.name,
          version: a.activity_type.version
        }
      })
      $dep_count += 1
    end
  end
end

resp = $swf_client.list_activity_types({
  domain: DOMAIN,
  registration_status: "REGISTERED",
})

deprecate_old_activities(resp.type_infos)

while not resp.next_page_token.nil?
  resp = $swf_client.list_activity_types({
    domain: DOMAIN,
    registration_status: "REGISTERED",
    next_page_token: resp.next_page_token
  })

  deprecate_old_activities(resp.type_infos)
end

puts "Deprecated #{$dep_count} activity types."