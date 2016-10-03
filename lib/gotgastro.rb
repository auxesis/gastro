require 'helpers'
require 'sinatra/cookies'
require 'rest-client'

module GotGastro
  class App < Sinatra::Base
    set :root, Pathname.new(__FILE__).parent

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper
    helpers Sinatra::RequireJSHelper
    helpers Sinatra::RequireCSSHelper
    helpers Sinatra::MetaTagHelper
    helpers Sinatra::Cookies

    configure do
      set :morph_api_key, ENV['MORPH_API_KEY']
    end

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
      @businesses = Business.find_near(@location,:within => 25)
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

    get '/privacy' do
      haml :privacy
    end

    get '/reset' do
      Business.dataset.destroy
      Offence.dataset.destroy

      url = 'https://api.morph.io/auxesis/gotgastro_scraper/data.json'

      # Create Businesses
      params = { :key => settings.morph_api_key, :query => "select * from 'businesses'" }
      result = RestClient.get(url, :params => params)
      businesses = JSON.parse(result)

      Business.unrestrict_primary_key
      businesses.each do |business|
        Business.create(business)
      end

      # Create Offences
      params = { :key => settings.morph_api_key, :query => "select * from 'offences'" }
      result = RestClient.get(url, :params => params)
      offences = JSON.parse(result)

      Offence.unrestrict_primary_key
      offences.each do |offence|
        Offence.create(offence)
      end

      "OK"
    end

    get '/metrics' do
      content_type :json
      {
        'businesses' => Business.count,
        'offences' => Offence.count,
      }.to_json
    end
  end
end
