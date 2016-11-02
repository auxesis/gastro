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

  task :destroy do
    puts "Destroying development database"
    system("mysql -u root -e 'DROP DATABASE IF EXISTS gotgastro_development;'")
    puts "Destroying development user"
    system(%(mysql -u root -e "DELETE FROM mysql.user WHERE user = 'gotgastro_dev';"))
    system(%(mysql -u root -e "DROP USER 'gotgastro_dev'@'localhost';"))

    puts "Destroying test database"
    system("mysql -u root -e 'DROP DATABASE IF EXISTS gotgastro_test;'")
    puts "Destroying test user"
    system(%(mysql -u root -e "DROP USER 'gotgastro_test'@'localhost';"))
  end
end

task :assets do
  node_path = 'node_modules/.bin'
  css_path  = 'lib/gotgastro/public/css'
  js_path   = 'lib/gotgastro/public/js'
  system("#{node_path}/cleancss --debug -o #{css_path}/main.min.css #{css_path}/main.css")
  system("#{node_path}/uglifyjs --verbose -o #{js_path}/index.min.js #{js_path}/index.js")
  system("#{node_path}/uglifyjs --verbose -o #{js_path}/search.min.js #{js_path}/search.js")
end
