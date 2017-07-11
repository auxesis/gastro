require 'helpers'
require 'sinatra/cookies'
require 'active_support'
require 'active_support/core_ext'
require 'rufus-scheduler'

module GotGastro
  class App < Sinatra::Base
    set :root, Pathname.new(__FILE__).parent.join('gotgastro')
    set :show_exceptions, :after_handler unless development?
    set :scheduler, Rufus::Scheduler.new

    helpers Sinatra::LinkToHelper
    helpers Sinatra::PageTitleHelper
    helpers Sinatra::RequireJSHelper
    helpers Sinatra::RequireCSSHelper
    helpers Sinatra::MetaTagHelper
    helpers Sinatra::Cookies
    helpers Sinatra::TimeHelpers
    helpers Sinatra::GoogleMapsHelpers

    before do
      # Set the location cookie if we've got a new lat/lng param.
      #
      # This allows us to keep track of location across requests, so we don't
      # have to keep prompting the user for where they are.
      cookies[:location] ||= '-33.8675,151.207' # set default location to Sydney
      cookies[:location] = "#{params[:lat]},#{params[:lng]}" if params[:lat] && params[:lng]
      cookies[:address] = params[:address] if params[:address]

      # Create a location object for lookups.
      lat, lng = URI.decode(cookies[:location]).split(',')
      address = cookies[:address] || ''
      @location = Business.new(:lat => lat, :lng => lng, :address => CGI::unescape(address))
    end

    configure do
      # Check on imports at 10:00 every Saturday
      scheduler.cron('0 10 * * 6') do
        GotGastro::Workers::MonitorImports.perform_async
      end
    end

    not_found do
      status 404
      haml :not_found
    end

    error 500 do
      status 500
      haml :error
    end

    get '/' do
      cache_control :public, :max_age => 86400
      haml :index
    end

    get '/search' do
      @businesses_dataset = Business.find_near(@location,:within => 25)
      @businesses = @businesses_dataset.all
      haml :search
    end

    get '/business/:id' do
      @business = Business[params[:id]]
      if @business
        haml :detail
      else
        halt 404
      end
    end

    get '/about' do
      cache_control :public, :max_age => 86400
      haml :about
    end

    get '/report' do
      cache_control :public, :max_age => 86400
      haml :report
    end

    get '/privacy' do
      cache_control :public, :max_age => 86400
      haml :privacy
    end

    post '/alert' do
      attrs = (params[:alert] || {}).merge({
        :host => "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
      })
      @alert = AlertSignupService.new(attrs)

      if @alert.save
        haml :'alerts/new'
      else
        status 400
        haml :'alerts/invalid_new'
      end
    end

    get '/alert/:confirmation_id/confirm' do
      @alert = AlertSignupService.find(params[:confirmation_id])
      if @alert
        if @alert.confirm!
          haml :'alerts/confirmation'
        else
          debug("Couldn't confirm this alert: #{@alert.inspect}")
          halt 500
        end
      else
        halt 404
      end
    end

    get '/alert/:confirmation_id/unsubscribe' do
      @alert = Alert.first(:confirmation_id => params[:confirmation_id])
      if @alert
        @alert.unsubscribed_at = Time.now
        @alert.save
        haml :'alerts/unsubscribe'
      else
        halt 404
      end
    end

    get '/alert/:confirmation_id/edit' do
      @alert = Alert.first(:confirmation_id => params[:confirmation_id])
      if @alert
        haml :'alerts/edit'
      else
        halt 404
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
        haml :'alerts/edit'
      else
        halt 404
      end
    end

    def self.get_or_post(url,&block)
      get(url,&block)
      post(url,&block)
    end

    get_or_post '/reset' do
      if params[:token] != config['settings']['reset_token']
        halt 404
        return 'ERROR'
      end

      GotGastro::Workers::Import.perform_async(params[:token])

      status 201
      'OK'
    end

    get '/health_checks' do
      content_type :json

      checks = [
        GotGastro::Monitors::CheckImportsCountInLastWeek,
        GotGastro::Monitors::CheckLastImportStatus
      ].each(&:run)

      checks.to_json
    end

    get '/metrics' do
      content_type :json

      metrics = {
        businesses: Business.count,
        offences:   Offence.count,
        imports:    {
          count:             Import.count,
          last_7_days_count: Import.where(:created_at => 1.week.ago..Time.now).count
        }
      }

      if Import.last
        metrics[:imports].merge!({
          last_import: {
            started_at:  Import.last.created_at,
            finished_at: Import.last.updated_at,
            duration:    Import.last.duration,
          },
          last_import_human: {
            started_at:  time_ago_in_words(Import.last.created_at) + ' ago',
            finished_at: time_ago_in_words(Import.last.updated_at) + ' ago',
            duration:    distance_of_time(Import.last.duration),
          }
        })
      end

      metrics.to_json
    end

    get '/env' do
      if params[:token] != config['settings']['reset_token']
        halt 404
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

    get '/alerts' do
      if params[:token] != config['settings']['reset_token']
        halt 404
      end

      content_type :json
      {
        :alerts => Alert.all
      }.to_json
    end

    get '/offences' do
      if params[:token] != config['settings']['reset_token']
        halt 404
      end
      limit = params[:limit] || 10

      content_type :json
      {
        :offences => Offence.order(:date).reverse.limit(limit).all
      }.to_json
    end
  end
end
