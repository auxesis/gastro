$: << File.expand_path(File.join(__FILE__, '..', 'lib'))

require 'sinatra/base'
require 'gotgastro'
require 'rack-google-analytics'

def root
  @root ||= Pathname.new(__FILE__).parent.join('lib')
end

def public_folder
  @public ||= root + 'public'
end

# Serve static assets before everything else
use Rack::Static, :urls => %w(/css /img /fonts /js), :root => public_folder
# Google Analytics
#use Rack::GoogleAnalytics, :tracker => 'UA-58647844-1' if environment == 'production'

use GotGastro::App
run Sinatra::Application
