ENV['RACK_ENV'] = 'test'

require 'pathname'
lib = Pathname.new(__FILE__).parent.parent.join('lib').to_s
$LOAD_PATH << lib
spec = Pathname.new(__FILE__).parent.to_s
$LOAD_PATH << spec
require 'capybara/rspec'
require 'rack/test'
require 'pry'
require 'webmock/rspec'
require 'mail'
require 'sidekiq/testing'
require 'delorean'
require 'helpers/test_data'
require 'helpers/env_test'

include GotGastro::Env::Test

# Drop this into /spec/support/matchers
# Usage: result.should be_url
# Passes if result is a valid url, returns error "expected result to be url" if not.

# Matcher to see if a string is a URL or not.
RSpec::Matchers.define :be_url do |expected|
  # The match method, returns true if valie, false if not.
  match do |actual|
    # Use the URI library to parse the string, returning false if this fails.
    URI.parse(actual) rescue false
  end
end

RSpec.configure do |config|
  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Run all migrations before all tests
  config.before(:all) do
    Sequel::Migrator.run(DB, 'db/migrations')
  end

  # Roll back changes to database after each test
  config.around(:each) do |example|
    DB.transaction(:rollback=>:always, :auto_savepoint=>true){example.run}
  end

  # Clear queues
  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  # Roll back environment variable changes
  config.after(:each) do
    restore_env
  end

  # Roll back the clock
  config.include Delorean
  config.after(:each) do
    back_to_the_present
  end
end

Mail.defaults do
  delivery_method :test
end

Sidekiq::Testing.fake!

# Define the Rack::Test/Capybara app by reading in the config.ru
def app
  app, _ = Rack::Builder.parse_file(File.expand_path('../../config.ru', __FILE__))
  return app
end

Capybara.app = app
