require 'helpers'

module GotGastro
  class App < Sinatra::Base
    set :root, Pathname.new(__FILE__).parent

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper
    helpers Sinatra::RequireJSHelper
    helpers Sinatra::RequireCSSHelper
    helpers Sinatra::MetaTagHelper

    get '/' do
      haml :index
    end

    get '/search' do
      haml :search
    end

    get '/detail' do
      haml :detail
    end
  end
end
