require 'spec_helper'

include Rack::Test::Methods
include Mail::Matchers

describe 'Alerts', :type => :feature do
  let(:origin) { Business.new(:lat => -33.1234, :lng => 150.5678) }
  let(:within_25km) {
    lats = (1..16).map {|i| origin.lat + i * 0.01 }
    lngs = (1..16).map {|i| origin.lng + i * 0.01 }

    lats.zip(lngs).each_with_index do |(lat, lng), i|
      Business.create(:name => "#{lat},#{lng},#{i}", :lat => lat, :lng => lng)
    end
  }
  let(:within_150km) {
    lats = (1..16).map {|i| origin.lat + i * 0.1 }
    lngs = (1..16).map {|i| origin.lng + i * 0.1 }

    lats.zip(lngs).each do |lat, lng|
      Business.create(:name => "#{lat},#{lng}", :lat => lat, :lng => lng)
    end
  }

  before(:each) do
    Mail::TestMailer.deliveries.clear
  end

  it 'should send a confirmation mail on sign up' do
    within_25km && within_150km

    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}&alert=hello"
    fill_in 'alert[email]', :with => 'hello@example.org'
    click_on 'Create alert'

    expect(Mail::TestMailer.deliveries.size).to be 1
  end
end
