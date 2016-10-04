require 'spec_helper'

include Rack::Test::Methods

describe 'Data reset', :type => :feature do

  let(:mocks) { Pathname.new(__FILE__).parent.join('mocks') }
  let(:business_json) { mocks.join('businesses.json').read }
  let(:offence_json) { mocks.join('offences.json').read }

  before(:each) do
    stub_request(:get,
      "https://api.morph.io/auxesis/gotgastro_scraper/data.json?key&query=select%20*%20from%20'businesses'"
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      "https://api.morph.io/auxesis/gotgastro_scraper/data.json?key&query=select%20*%20from%20'offences'"
      ).to_return(:status => 200, :body => offence_json)
  end

  it 'should create records' do
    before = Business.count
    visit '/reset'
    after = Business.count

    expect(after).to be > before
  end

  it 'should create associations' do
    visit '/reset'

    Business.each do |biz|
      expect(biz.offences.size).to be > 0
    end
  end

  it 'should create a record of the reset' do
    before = Reset.count
    visit '/reset'
    after = Reset.count

    expect(after).to be > before
  end

  it 'should report the duration of the reset' do
    visit '/reset'

    expect(Reset.last.duration).to_not be nil
  end
end
