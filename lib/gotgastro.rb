require 'helpers'
require 'sinatra/cookies'

module GotGastro
  class App < Sinatra::Base
    set :root, Pathname.new(__FILE__).parent

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper
    helpers Sinatra::RequireJSHelper
    helpers Sinatra::RequireCSSHelper
    helpers Sinatra::MetaTagHelper
    helpers Sinatra::Cookies

    before do
      # Set the location cookie if we've got a new lat/lng param.
      #
      # This allows us to keep track of location across requests, so we don't
      # have to keep prompting the user for where they are.
      cookies[:location] ||= "-33.8675,151.207" # set default location to Sydney
      cookies[:location] = "#{params[:lat]},#{params[:lng]}" if params[:lat] && params[:lng]
      lat, lng = URI.decode(cookies[:location]).split(',')
      # Create a location object for lookups.
      @location = Business.new(:lat => lat, :lng => lng)
    end

    get '/' do
      haml :index
    end

    get '/search' do
      #@businesses = Business.dataset.by_distance(@location).all
      @businesses = Business.dataset.around(@location,25).all
      haml :search
    end

    get '/business/:id' do
      @business = Business[params[:id]]
      if @business
        haml :detail
      else
        status '404'
        "not found"
      end
    end

    get '/reset' do
      Business.dataset.destroy
      datasets = %w(vic).map do |state|
        p JSON.parse(root.join("db/datasets/#{state}.join").read)
      end

      datasets.each do |dataset|
        dataset.each do |attrs|
          Business.create(attrs)
        end
      end

      "OK"
    end
  end
end
