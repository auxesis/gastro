require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'rest-client'

module GotGastro
  module Workers
    class Import
      include Sidekiq::Worker

      def perform(token)
        import = ::Import.create(:token => token)
        info("Data import id #{import.id} started at #{import.created_at}")

        # Create Businesses
        Business.unrestrict_primary_key
        businesses.each do |business|
          if b = Business[business['id']]
            b.update(business)
          else
            Business.create(business)
          end
        end

        # Create Offences
        Offence.unrestrict_primary_key
        offences.each do |offence|
          if o = Offence.first(:link => offence['link'])
            o.update(offence)
          else
            Offence.create(offence)
          end
        end

        import.save
        EmailAlerts.perform_async
        info("Data import id #{import.id} completed at #{import.updated_at}")
      end

      def url
        'https://api.morph.io/auxesis/gotgastro_scraper/data.json'
      end

      def businesses
        return @businesses if @businesses
        params = {
          :key => config['settings']['morph_api_key'],
          :query => "select * from 'businesses'"
        }
        result = RestClient.get(url, :params => params)
        @businesses = JSON.parse(result)
      end

      def offences
        return @offences if @offences
        params = {
          :key => config['settings']['morph_api_key'],
          :query => "select * from 'offences'"
        }
        result = RestClient.get(url, :params => params)
        @offences = JSON.parse(result)
      end
    end
  end
end
