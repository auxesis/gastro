require 'spec_helper'

include Rack::Test::Methods
include GotGastro::Env::Test

describe 'Data import', :type => :feature do
  include_context 'test data'

  before(:each) do
    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key=.*&query=select%20\*%20from%20'businesses'}
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'offences'}
      ).to_return(:status => 200, :body => offence_json)
  end

  before(:each) do
    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)
  end

  it 'should require a token' do
    visit '/reset'
    expect(page.status_code).to be 404

    visit "/reset?token=#{gastro_reset_token}"
    expect(page.status_code).to be 201
  end

  it 'should create records' do
    before = Business.count
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    after = Business.count
    expect(after).to be > before
  end

  it 'should create associations' do
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain

    Business.each do |biz|
      expect(biz.offences.size).to be > 0
    end
  end

  it 'should create a record of the import' do
    before = Import.count
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    after = Import.count

    expect(after).to be > before
  end

  it 'should report the duration of the import' do
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain

    expect(Import.last.duration).to_not be nil
  end

  let(:morph_api_key_for_update) {
    Digest::MD5.new.hexdigest(rand(Time.now.to_i).to_s)
  }

  it 'should update when there is new data' do
    # First import
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    expect(Offence.map(:created_at).uniq.size).to be 1
    old_offences = Offence.map(:id)

    # Time shift
    time_travel_to('tomorrow')

    # For second import
    stub_request(:get,
      "https://api.morph.io/auxesis/gotgastro_scraper/data.json?key=#{morph_api_key_for_update}&query=select%20*%20from%20'offences'"
      ).to_return(:status => 200, :body => new_offence_json)

    # Second import
    set_environment_variable('MORPH_API_KEY', morph_api_key_for_update)
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    new_offences = Offence.map(:id)
    expect(new_offences).to_not eq(old_offences)
    expect(new_offences.size).to be > old_offences.size
    expect(Offence.map(:created_at).uniq.size).to be 2
  end
end
