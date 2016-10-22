require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'mail'
require 'active_support/core_ext/time'

module GotGastro
  module Workers
    class EmailAlerts
      include Sidekiq::Worker

      def perform
        import = ::Import.last
        alerts = Alert.where{confirmed_at !~ nil}.where(:unsubscribed_at => nil)
        alerts.each do |alert|
          conditions = ['offences.created_at >= :alert', {:alert => alert.created_at}]
          businesses = Business.find_near(alert.location, :within => alert.distance)
          offences   = Offence.join(businesses, :id => :business_id).where(*conditions).all

          offences.select! do |offence|
            if alert.alerted?(offence)
              false
            else
              attrs = {
                :offence_id => offence.id,
                :alert_id   => alert.id,
                :import_id  => import.id
              }
              AlertsOffences.create(attrs)
            end
          end

          notify(:alert => alert, :offences => offences) if offences.size > 0
        end
      end

      def notify(opts={})
        alert    = opts[:alert]
        offences = opts[:offences]

        raise ArgumentError unless alert && offences

        mail = Mail.new
        mail.charset = "UTF-8"
        mail.from    = 'alerts@gotgastroagain.com'
        mail.to      = alert.email
        mail.subject = "#{offences.count} new food safety warnings near #{alert.address}"
        mail.body    = <<-BODY.gsub(/^ {10}/, '')
          The following new food safety warnings have been found within #{alert.distance}km of #{alert.address}.

          #{format(offences, Business.new(:lat => alert.lat, :lng => alert.lng))}

          Thanks,
          Got Gastro

          Unsubscribe: #{config['settings']['baseurl']}/alert/#{alert.confirmation_id}/unsubscribe
          Change: #{config['settings']['baseurl']}/alert/#{alert.confirmation_id}/edit
        BODY

        GotGastro::Workers::EmailWorker.perform_async(mail)
      end

      def format(offences, origin)
        template = <<-TEMPLATE.gsub(/^ {10}/, '')
          <% offences.each do |offence| %>
          Business: <%= offence.business.name %>
          Address: <%= offence.business.address %>
          Distance away: <%= "%.2f" % offence.business.distance_from(origin) %>km
          Date: <%= offence.date %>
          Description: <%= offence.description.strip %>
          <% end %>
        TEMPLATE

        erb = ERB.new(template, nil, '-')
        erb.result(binding)
      end
    end
  end
end
