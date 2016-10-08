require 'helpers'
require 'sinatra/cookies'
require 'rest-client'
require 'active_support'
require 'active_support/core_ext'
require 'mail'

module GotGastro
  class App < Sinatra::Base
    set :root, Pathname.new(__FILE__).parent

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper
    helpers Sinatra::RequireJSHelper
    helpers Sinatra::RequireCSSHelper
    helpers Sinatra::MetaTagHelper
    helpers Sinatra::Cookies

    def self.set_or_raise(key, value)
      if value.nil? or value.blank?
        raise ArgumentError, "Value for '#{key}' was not specified"
      else
        set(key, value)
      end
    end

    configure do
      set_or_raise :morph_api_key, ENV['MORPH_API_KEY']
      set_or_raise :reset_token, ENV['GASTRO_RESET_TOKEN']
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

    get '/about' do
      haml :about
    end

    get '/report' do
      haml :report
    end

    get '/privacy' do
      haml :privacy
    end

    post '/alert' do
      attrs = params[:alert].dup.merge({
        :host => "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
      })
      @alert = AlertSignupService.new(attrs)

      if @alert.save
        haml :alert
      else
        status 500
      end
    end

    get '/alert/:confirmation_id/confirm' do
      @alert = AlertSignupService.find(params[:confirmation_id])
      if @alert
        if @alert.confirm!
          haml :alert_confirmation
        else
          puts "[debug] Couldn't confirm this alert: #{@alert.inspect}"
          status 500
        end
      else
        status 404
      end
    end

    def self.get_or_post(url,&block)
      get(url,&block)
      post(url,&block)
    end

    get_or_post '/reset' do
      if params[:token] != settings.reset_token
        status 404
        return "ERROR"
      end

      status 201

      reset = Reset.create(:token => params[:token])

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

      reset.save

      "OK"
    end

    get '/metrics' do
      content_type :json

      metrics = {
        'businesses' => Business.count,
        'offences' => Offence.count,
      }

      if Reset.last
        metrics.merge!({
          'last_reset_at' => Reset.last.created_at,
          'last_reset_duration' => Reset.last.duration,
        })
      end

      metrics.to_json
    end

    get '/env' do
      if params[:token] != settings.reset_token
        status 404
        return "ERROR"
      end

      content_type :json
      {
        :config => config,
        :env    => ENV.to_hash,
        :mail   => Mail.delivery_method.settings,
      }.to_json
    end
  end
end
