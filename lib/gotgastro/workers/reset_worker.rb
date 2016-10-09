require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'rest-client'

module GotGastro
  module Workers
    class ResetWorker
      include Sidekiq::Worker

      def perform(token)
        reset = Reset.create(:token => token)
        info("Data reset started at #{reset.created_at}")

        Business.dataset.destroy
        Offence.dataset.destroy

        url = 'https://api.morph.io/auxesis/gotgastro_scraper/data.json'

        # Create Businesses
        params = {
          :key => config['settings']['morph_api_key'],
          :query => "select * from 'businesses'"
        }
        result = RestClient.get(url, :params => params)
        businesses = JSON.parse(result)

        Business.unrestrict_primary_key
        businesses.each do |business|
          Business.create(business)
        end

        # Create Offences
        params = { :key => config['settings']['morph_api_key'], :query => "select * from 'offences'" }
        result = RestClient.get(url, :params => params)
        offences = JSON.parse(result)

        Offence.unrestrict_primary_key
        offences.each do |offence|
          Offence.create(offence)
        end

        reset.save
        info("Data reset completed at #{reset.updated_at}")
      end
    end
  end
end
