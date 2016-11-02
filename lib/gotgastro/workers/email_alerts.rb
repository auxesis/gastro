require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'mail'
require 'active_support/core_ext/time'
require 'tilt/haml'

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

          # FIXME(auxesis): do a group_by business_id on offences so there is only one entry per business

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
        mail.text_part = text_part(:alert => alert, :offences => offences)
        mail.html_part = html_part(:alert => alert, :offences => offences)

        GotGastro::Workers::EmailWorker.perform_async(mail)
      end

      def view(filename)
        Pathname.new(__FILE__).parent.parent.parent.join('views').join(filename).to_s
      end

      def html_part(opts={})
        alert    = opts[:alert]
        offences = opts[:offences]

        part = Mail::Part.new
        part.content_type 'text/html; charset=UTF-8'

        template = Tilt::HamlTemplate.new(view('alerts/email.haml'))
        part.body = template.render(self, :alert => alert, :offences => offences)

        return part
      end

      def text_part(opts={})
        alert    = opts[:alert]
        offences = opts[:offences]

        part = Mail::Part.new
        template = Tilt::ERBTemplate.new(view('alerts/email_text.erb'))
        part.body = template.render(self, :alert => alert, :offences => offences)

        return part
      end
    end
  end
end
