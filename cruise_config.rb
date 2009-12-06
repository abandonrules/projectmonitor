# Project-specific configuration for CruiseControl.rb
require 'fileutils'

Project.configure do |project|
  project.email_notifier.emails = ["pivotal-pulse@example.com"]
  ENV['CRUISE_PROJECT_NAME'] = project.name
end
