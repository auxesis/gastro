monitors_path = Pathname.new(__FILE__).parent.join('monitors').join('*.rb')
Dir.glob(monitors_path).each { |helper| require(helper) }
