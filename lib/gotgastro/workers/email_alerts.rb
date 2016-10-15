require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'mail'

module GotGastro
  module Workers
    class EmailAlerts
      include Sidekiq::Worker

      def perform
        Alert.where{confirmed_at !~ nil}.where(:unsubscribed_at => nil).each do |alert|
          businesses = Business.find_near(alert.location, :within => alert.distance)
          conditions = { Sequel.qualify(:offences, :created_at) => Time.now.beginning_of_day..Time.now.end_of_day }
          offences = Offence.join(businesses, :id => :business_id).where{conditions}.all

          mail = Mail.new
          mail.from    = 'alerts-confirm@gotgastroagain.com'
          mail.to      = alert.email
          mail.subject = "#{offences.count} new food safety warnings near #{alert.address}"
          mail.body    = <<-BODY.gsub(/^ {12}/, '')
            The following new food safety warnings have been found within #{alert.distance}km of #{alert.address}.

            #{format(offences)}

            Thanks,
            Got Gastro

            Unsubscribe: #{@host}/alert/#{alert.confirmation_id}/unsubscribe
          BODY
          GotGastro::Workers::EmailWorker.perform_async(mail)
        end
      end

      def format(offences)
        template = <<-TEMPLATE.gsub(/^ {10}/, '')
          <% offences.each do |offence| %>
          Business: <%= offence.business.name %>
          Address: <%= offence.business.address %>
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
