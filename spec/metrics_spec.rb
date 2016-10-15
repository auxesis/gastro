require 'spec_helper'

include Rack::Test::Methods
include GotGastro::Env::Test

describe 'Got Gastro metrics', :type => :feature do
  include_context 'test data'

  it 'should expose counts of core data' do
    visit '/metrics'

    metrics = JSON.parse(body)

    expect(metrics['businesses']).to_not be nil
    expect(metrics['offences']).to_not be nil
  end

  it 'should expose metrics from last reset' do
    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'businesses'}
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'offences'}
      ).to_return(:status => 200, :body => offence_json)

    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)

    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    visit '/metrics'

    metrics = JSON.parse(body)

    expect(metrics['last_import_at']).to_not be nil
    expect(metrics['last_import_duration']).to_not be nil
    expect(metrics['last_import_at_human']).to_not be nil
  end

  it 'should indicate if the current reset is still running' do
    # This is a bit of a code smell, because it requires poking around the data
    # structures behind the scenes to simulate a currently running reset
    # operation.
    #
    # Ideally the test could do a request to /reset that blocks for a duration
    # of time, and in parallel do a request to /metrics to check the last reset
    # status.
    #
    # Of course, this has trade-offs: the test would depend on timely execution,
    # because the block could complete before the call to /metrics completes.
    #
    # The below is an OK trade off for now.

    Import.create
    visit '/metrics'

    metrics = JSON.parse(body)

    expect(metrics['last_import_duration']).to be -1
  end
end
