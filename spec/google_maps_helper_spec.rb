require 'spec_helper'

include Rack::Test::Methods
include Sinatra::GoogleMapsHelpers

describe 'GoogleMapsHelpers' do
  include_context 'test data'

  before(:each) do
    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)
    set_environment_variable('FB_APP_ID', fb_app_id)
  end

  it 'should ensure the url is no longer than 2000 characters' do
    thousands_of_results

    businesses = Business.all
    gmaps_api_key = config['settings']['gmaps_api_key']

    map_url = google_map(:api_key => gmaps_api_key, :businesses => businesses, :location => origin)
    expect(map_url.size).to be <= 2000
  end
end
