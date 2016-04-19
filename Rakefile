#!/usr/bin/env ruby

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task :default => [:spec]

namespace :db do
  task :create do
    puts "Creating development database"
    system("mysql -u root -e 'CREATE DATABASE IF NOT EXISTS gotgastro_development;'")
    puts "Creating development user"
    system(%(mysql -u root -e "CREATE USER 'gotgastro_dev'@'localhost' IDENTIFIED BY 'dev';"))
    system(%(mysql -u root -e "GRANT ALL PRIVILEGES ON gotgastro_development.* TO 'gotgastro_dev'@'localhost';"))

    puts "Creating test database"
    system("mysql -u root -e 'CREATE DATABASE IF NOT EXISTS gotgastro_test;'")
    puts "Creating test user"
    system(%(mysql -u root -e "CREATE USER 'gotgastro_test'@'localhost' IDENTIFIED BY 'test';"))
    system(%(mysql -u root -e "GRANT ALL PRIVILEGES ON gotgastro_test.* TO 'gotgastro_test'@'localhost';"))
  end
end
