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
      @location = Business.new(:lat => params[:lat], :lng => params[:lng])
      @points = Business.dataset.by_distance(@location).limit(10).all
      haml :search
    end

    get '/business/:id' do
      @business = Business[params[:id]]
      haml :detail
    end
  end
end
