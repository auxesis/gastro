helpers_path = Pathname.new(__FILE__).parent.join('helpers').join('*.rb')
Dir.glob(helpers_path).each { |helper| require(helper) }
