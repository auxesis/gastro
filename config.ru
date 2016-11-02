$: << File.expand_path(File.join(__FILE__, '..', 'lib'))

# So we know what production looked like when we exit
at_exit do
  p ENV
end if ENV['RACK_ENV'] == 'production'

require 'sinatra/base'
require 'newrelic_rpm'
require 'gotgastro/initializer'
require 'gotgastro'
require 'rack-google-analytics'
require 'tilt/haml'
require 'rack/ssl'

def root
  @root ||= Pathname.new(__FILE__).parent.join('lib')
end

def public_folder
  @public ||= root.join('gotgastro').join('public')
end

# gzip compress everything
use Rack::Deflater
# Serve static assets before everything else
use Rack::Static, :urls => %w(/css /img /fonts /js), :root => public_folder
# Google Analytics
use Rack::GoogleAnalytics, :tracker => 'UA-85193424-1' if environment == 'production'

use Rack::SSL if environment == 'production'
use GotGastro::App
run Sinatra::Application
