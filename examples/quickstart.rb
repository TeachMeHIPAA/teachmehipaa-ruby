# frozen_string_literal: true

# Lists the Courses, the Organization's Compliance summary and its first
# Learners in the Sandbox.
#
#   TMH_CLIENT_ID=cli_... TMH_CLIENT_SECRET=tmh_cs_... bundle exec ruby -Ilib examples/quickstart.rb

require "teachmehipaa"

client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  environment: :sandbox,
)

puts "Courses:"
client.courses.list.auto_paging_each { |course| puts "  #{course.course_id}: #{course.title}" }

summary = client.compliance.retrieve
puts "#{(summary.compliant_rate * 100).round}% of Learners are compliant"

puts "First Learners:"
client.learners.list(limit: 10).auto_paging_each.first(10).each do |learner|
  puts "  #{learner.email} (#{learner.status})"
end
