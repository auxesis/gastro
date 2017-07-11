require 'spec_helper'

describe GotGastro::Helpers::GoogleMapsHelpers do

  include GotGastro::Helpers::GoogleMapsHelpers

  include_context 'test data'

  before(:each) do
    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)
    set_environment_variable('FB_APP_ID', fb_app_id)
  end

  it 'should ensure the url is no longer than 2000 characters' do
    thousands_of_results && some_prosecutions

    businesses = Business.all
    gmaps_api_key = config['settings']['gmaps_api_key']

    map_url = google_map(:api_key => gmaps_api_key, :businesses => businesses, :location => origin)
    expect(map_url.size).to be <= 2000
  end

  it 'should not include duplicate locations in separate marker lists' do
    thousands_of_results && some_prosecutions

    businesses = Business.all
    gmaps_api_key = config['settings']['gmaps_api_key']
    map_url = google_map(:api_key => gmaps_api_key, :businesses => businesses, :location => origin)
    expect(map_url.size).to be <= 2000

    # Parse the url into an array of markers
    url = Addressable::URI.parse(map_url)
    markers = url.query_values(Array).select {|k, v| k == 'markers' }.map {|k,v| v}

    # Build up a list of all the locations specified for markers
    locations = []
    markers.each { |marker| locations.concat(marker.split('|')[2..-1]) }

    # Check they're uniq
    expect(locations.uniq.size).to eq(locations.size)
  end
end
