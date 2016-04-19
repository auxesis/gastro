ENV['RACK_ENV'] = 'test'

require 'pathname'
lib = Pathname.new(__FILE__).parent.parent.join('lib').to_s
$LOAD_PATH << lib
require 'capybara/rspec'
require 'rack/test'
require 'pry'

RSpec.configure do |config|
  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Run all migrations before all tests
  config.before(:all) do
    Sequel::Migrator.run(DB, "db/migrations")
  end

  # Roll back changes to database after each test
  config.around(:each) do |example|
    DB.transaction(:rollback=>:always, :auto_savepoint=>true){example.run}
  end
end

# Define the Rack::Test/Capybara app by reading in the config.ru
def app
  app, _ = Rack::Builder.parse_file(File.expand_path('../../config.ru', __FILE__))
  return app
end

Capybara.app, _ = app
