require 'spec_helper'

include Rack::Test::Methods

describe 'Got Gastro metrics', :type => :feature do
  it 'should expose counts of core data' do
    visit '/metrics'

    metrics = JSON.parse(body)

    expect(metrics['businesses']).to_not be nil
    expect(metrics['offences']).to_not be nil
  end
end
