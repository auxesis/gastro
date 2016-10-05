ENV['RACK_ENV'] = 'test'

require 'pathname'
lib = Pathname.new(__FILE__).parent.parent.join('lib').to_s
$LOAD_PATH << lib
require 'capybara/rspec'
require 'rack/test'
require 'pry'
require 'webmock/rspec'

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

ENV['GASTRO_RESET_TOKEN'] = Digest::MD5.new.hexdigest(Time.now.to_i.to_s)
ENV['MORPH_API_KEY'] = Digest::MD5.new.hexdigest((Time.now.to_i + 10).to_s)

Capybara.app, _ = app
