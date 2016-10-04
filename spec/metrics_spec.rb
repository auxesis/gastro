require 'spec_helper'

include Rack::Test::Methods

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

  it 'should expose metrics from last reset' do
    stub_request(:get,
      "https://api.morph.io/auxesis/gotgastro_scraper/data.json?key&query=select%20*%20from%20'businesses'"
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      "https://api.morph.io/auxesis/gotgastro_scraper/data.json?key&query=select%20*%20from%20'offences'"
      ).to_return(:status => 200, :body => offence_json)

    visit "/reset?token=#{ENV['GASTRO_RESET_TOKEN']}"
    visit '/metrics'

    metrics = JSON.parse(body)

    expect(metrics['last_reset_at']).to_not be nil
    expect(metrics['last_reset_duration']).to_not be nil
  end
end
