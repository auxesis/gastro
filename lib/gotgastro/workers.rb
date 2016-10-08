$: << File.expand_path(File.join(__FILE__, '..', '..'))

require 'rubygems'
require 'gotgastro/initializer'
require 'sidekiq'
require 'redis'
require 'sidekiq/api'

workers_path = Pathname.new(__FILE__).parent.join('workers').join('*.rb')
Dir.glob(workers_path).each { |worker| require(worker) }
