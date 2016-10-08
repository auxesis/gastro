require 'spec_helper'

include Rack::Test::Methods

describe 'Data reset', :type => :feature do

  let(:mocks) { Pathname.new(__FILE__).parent.join('mocks') }
  let(:business_json) { mocks.join('businesses.json').read }
  let(:offence_json) { mocks.join('offences.json').read }

  before(:each) do
    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key=.*&query=select%20\*%20from%20'businesses'}
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'offences'}
      ).to_return(:status => 200, :body => offence_json)
  end

  it 'should error if setttings value is not set' do
    # This isn't so great, because we're testing implementation (set_or_raise)
    # not the interface (booting the app without environment variables).
    expect {
      GotGastro::App.new.settings.set_or_raise(:hello, nil)
    }.to raise_error(ArgumentError)
  end

  it 'should require a token' do
    visit '/reset'
    expect(page.status_code).to be 404

    visit "/reset?token=#{ENV['GASTRO_RESET_TOKEN']}"
    expect(page.status_code).to be 201
  end

  it 'should create records' do
    before = Business.count
    visit "/reset?token=#{ENV['GASTRO_RESET_TOKEN']}"
    GotGastro::Workers::ResetWorker.drain
    after = Business.count
    expect(after).to be > before
  end

  it 'should create associations' do
    visit "/reset?token=#{ENV['GASTRO_RESET_TOKEN']}"
    GotGastro::Workers::ResetWorker.drain

    Business.each do |biz|
      expect(biz.offences.size).to be > 0
    end
  end

  it 'should create a record of the reset' do
    before = Reset.count
    visit "/reset?token=#{ENV['GASTRO_RESET_TOKEN']}"
    GotGastro::Workers::ResetWorker.drain
    after = Reset.count

    expect(after).to be > before
  end

  it 'should report the duration of the reset' do
    visit "/reset?token=#{ENV['GASTRO_RESET_TOKEN']}"
    GotGastro::Workers::ResetWorker.drain

    expect(Reset.last.duration).to_not be nil
  end
end
