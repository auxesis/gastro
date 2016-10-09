require 'spec_helper'

include Rack::Test::Methods
include GotGastro::Env::Test

describe 'Got Gastro metrics', :type => :feature do
  it 'should expose counts of core data' do
    visit '/metrics'

    metrics = JSON.parse(body)

    expect(metrics['businesses']).to_not be nil
    expect(metrics['offences']).to_not be nil
  end

  let(:mocks) { Pathname.new(__FILE__).parent.join('mocks') }
  let(:business_json) { mocks.join('businesses.json').read }
  let(:offence_json) { mocks.join('offences.json').read }
  let(:gastro_reset_token) { Digest::MD5.new.hexdigest(rand(Time.now.to_i).to_s) }
  let(:morph_api_key) { Digest::MD5.new.hexdigest(rand(Time.now.to_i).to_s) }

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
    GotGastro::Workers::ResetWorker.drain
    visit '/metrics'

    metrics = JSON.parse(body)

    expect(metrics['last_reset_at']).to_not be nil
    expect(metrics['last_reset_duration']).to_not be nil
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

    Reset.create
    visit '/metrics'

    metrics = JSON.parse(body)

    expect(metrics['last_reset_duration']).to be -1
  end
end
