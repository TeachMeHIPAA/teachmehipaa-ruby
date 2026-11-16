# frozen_string_literal: true

# Keeps TeachMeHIPAA's Learners in step with your own roster: everyone on
# the roster is created (and invited) or found by their External ID, your
# HR system's id for them, and Learners you no longer employ are offboarded.
# Safe to run as often as you like: a Learner who already exists is left as
# they are.
#
#   TMH_CLIENT_ID=cli_... TMH_CLIENT_SECRET=tmh_cs_... bundle exec ruby -Ilib examples/sync_roster.rb

require "teachmehipaa"

# Stands in for your HR system: everyone who should be taking training.
ROSTER = [
  { hr_id: "hr-1001", email: "ana@example.com", name: "Ana Example" },
  { hr_id: "hr-1002", email: "ben@example.com", name: "Ben Example" },
  { hr_id: "hr-1003", email: "cy@example.com", name: "Cy Example" },
].freeze

client = TeachMeHipaa::Client.new(
  client_id: ENV.fetch("TMH_CLIENT_ID"),
  client_secret: ENV.fetch("TMH_CLIENT_SECRET"),
  environment: :sandbox,
)

ROSTER.each do |person|
  learner = client.learners.upsert_by_external_id(person[:hr_id], email: person[:email], name: person[:name])
  puts "#{learner.created? ? "invited" : "already enrolled"}: #{learner.email}"
rescue TeachMeHipaa::ConflictError => e
  # One person's problem, such as no free Seat, shouldn't stop the sync.
  warn "skipped #{person[:email]}: #{e.code}"
end

on_roster = ROSTER.map { |person| person[:hr_id] }
client.learners.list(limit: 100).auto_paging_each do |learner|
  # A Learner without an External ID was added some other way, so the
  # roster doesn't speak for them.
  next if learner.external_id.nil? || on_roster.include?(learner.external_id)
  next if learner.status == TeachMeHipaa::LearnerStatus::REMOVED

  client.learners.offboard(learner.learner_id)
  puts "offboarded: #{learner.email}"
end
