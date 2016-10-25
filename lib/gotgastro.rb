require 'helpers'
require 'sinatra/cookies'
require 'active_support'
require 'active_support/core_ext'

module GotGastro
  class App < Sinatra::Base
    set :root, Pathname.new(__FILE__).parent

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper
    helpers Sinatra::RequireJSHelper
    helpers Sinatra::RequireCSSHelper
    helpers Sinatra::MetaTagHelper
    helpers Sinatra::Cookies
    helpers Sinatra::TimeHelpers

    before do
      # Set the location cookie if we've got a new lat/lng param.
      #
      # This allows us to keep track of location across requests, so we don't
      # have to keep prompting the user for where they are.
      cookies[:location] ||= "-33.8675,151.207" # set default location to Sydney
      cookies[:location] = "#{params[:lat]},#{params[:lng]}" if params[:lat] && params[:lng]
      cookies[:address] = params[:address] if params[:address]

      # Create a location object for lookups.
      lat, lng = URI.decode(cookies[:location]).split(',')
      address = cookies[:address] || ""
      @location = Business.new(:lat => lat, :lng => lng, :address => CGI::unescape(address))
    end

    get '/' do
      haml :index
    end

    get '/search' do
      @businesses = Business.find_near(@location,:within => 25).all
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
          debug("Couldn't confirm this alert: #{@alert.inspect}")
          status 500
        end
      else
        status 404
      end
    end

    get '/alert/:confirmation_id/unsubscribe' do
      @alert = Alert.first(:confirmation_id => params[:confirmation_id])
      if @alert
        @alert.unsubscribed_at = Time.now
        @alert.save
        haml :alert_unsubscribe
      else
        status 404
      end
    end

    get '/alert/:confirmation_id/edit' do
      @alert = Alert.first(:confirmation_id => params[:confirmation_id])
      if @alert
        haml :alert_edit
      else
        status 404
      end
    end

    def flash
      @flash ||= {}
    end

    post '/alert/:confirmation_id/edit' do
      @alert = Alert.first(:confirmation_id => params[:confirmation_id])
      if @alert
        @alert.distance = params[:alert][:distance]
        if @alert.save
          flash[:success] = 'Alert updated!'
        else
          flash[:danger] = 'There was a problem updating your alert :-('
        end
        haml :alert_edit
      else
        status 404
      end
    end

    def self.get_or_post(url,&block)
      get(url,&block)
      post(url,&block)
    end

    get_or_post '/reset' do
      if params[:token] != config['settings']['reset_token']
        status 404
        return "ERROR"
      end

      GotGastro::Workers::Import.perform_async(params[:token])

      status 201
      "OK"
    end

    get '/metrics' do
      content_type :json

      metrics = {
        'businesses' => Business.count,
        'offences' => Offence.count,
      }

      if Import.last
        metrics.merge!({
          'last_import_at' => Import.last.created_at,
          'last_import_at_human' => time_ago_in_words(Import.last.created_at) + ' ago',
          'last_import_duration' => Import.last.duration,
        })
      end

      metrics.to_json
    end

    get '/env' do
      if params[:token] != config['settings']['reset_token']
        status 404
        return "ERROR"
      end

      content_type :json
      {
        :config   => config,
        :database => database_config,
        :env      => Hash[ENV.sort],
        :mail     => Mail.delivery_method.settings,
        :queues   => Sidekiq::Stats.new
      }.to_json
    end
  end
end
