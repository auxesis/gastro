require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'mail'
require 'active_support/core_ext/time'
require 'tilt/haml'
require 'gotgastro/helpers'

module GotGastro
  module Workers
    class EmailAlerts
      include Sidekiq::Worker
      include GotGastro::Helpers::GoogleMapsHelpers

      def perform
        import = ::Import.last
        alerts = Alert.where{confirmed_at !~ nil}.where(:unsubscribed_at => nil)
        alerts.each do |alert|
          conditions = Sequel[:offences][:created_at] >= alert.created_at
          businesses = Business.find_near(alert.location, :within => alert.distance)
          offences   = Offence.join(businesses, :id => :business_id).where(conditions).all

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

        # business => [ offence ] mapping, roll up many offences into one business.
        pairs = {}
        offences.each do |offence|
          business = offence.business
          pairs[business] ||= []
          pairs[business] << offence
        end

        mail = Mail.new
        mail.charset = 'UTF-8'
        mail.from    = 'alerts@gotgastroagain.com'
        mail.to      = alert.email
        mail.subject = "#{offences.count} new food safety warnings near #{alert.address}"
        mail.text_part = text_part(:alert => alert, :to_alert => pairs)
        mail.html_part = html_part(:alert => alert, :to_alert => pairs)

        GotGastro::Workers::EmailWorker.perform_async(mail)
      end

      def view(filename)
        Pathname.new(__FILE__).parent.parent.join('views').join(filename).to_s
      end

      def html_part(opts={})
        alert    = opts[:alert]
        pairs    = opts[:to_alert]

        part = Mail::Part.new
        part.content_type 'text/html; charset=UTF-8'

        template = Tilt::HamlTemplate.new(view('alerts/email_html.haml'))
        part.body = template.render(self, :alert => alert, :pairs => pairs)

        return part
      end

      def text_part(opts={})
        alert    = opts[:alert]
        pairs    = opts[:to_alert]

        part = Mail::Part.new
        part.content_type 'text/plain; charset=UTF-8'
        template = Tilt::ERBTemplate.new(view('alerts/email_text.erb'))
        part.body = template.render(self, :alert => alert, :pairs => pairs)

        return part
      end
    end
  end
end
