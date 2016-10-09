ENV['RACK_ENV'] = 'test'

require 'pathname'
lib = Pathname.new(__FILE__).parent.parent.join('lib').to_s
$LOAD_PATH << lib
require 'capybara/rspec'
require 'rack/test'
require 'pry'
require 'webmock/rspec'
require 'mail'
require 'sidekiq/testing'

module GotGastro
  module Env
    module Test
      def restore_env
        ENV.replace(@original) if @original
        @original = nil
      end

      def delete_environment_variable(name)
        @original ||= ENV.to_hash
        ENV.delete(name)
      end

      def set_environment_variable(name, value)
        @original ||= ENV.to_hash
        ENV[name] = value
      end
    end
  end
end

include GotGastro::Env::Test

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

  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  config.after(:each) do
    restore_env
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

Capybara.app, _ = app
