require 'virtus'
require 'active_model'

services_path = Pathname.new(__FILE__).parent.join('services').join('*.rb')
Dir.glob(services_path).each { |service| require(service) }
