# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "minitest", ">= 5.25", "< 7"
gem "rake", "~> 13.0"
gem "rbs", "~> 3.9"
# Pinned: with no checked-in lockfile, a floating RuboCop turns new cops
# into surprise CI failures.
gem "rubocop", "1.92.2"
gem "rubocop-minitest", "0.41.0"
# The README's Sinatra webhook handler runs under the README doc test.
gem "sinatra", "~> 4.1"
# The Rails guide's initializer, job and webhook controller run under
# `rake test:rails`, in a process of their own. The gem itself never loads
# Rails.
gem "actionpack", ">= 7.1", "< 9"
gem "activejob", ">= 7.1", "< 9"
# The API reference (`bundle exec rake docs`): YARD renders the code's RDoc
# comments with rdoc (no longer a default gem from Ruby 4.0) and the Markdown
# guides with Redcarpet.
gem "rdoc", ">= 6.6"
# YARD's syntax highlighter loads irb, also no longer a default gem.
gem "irb", ">= 1.14"
gem "redcarpet", "~> 3.6"
gem "yard", "~> 0.9.37"
