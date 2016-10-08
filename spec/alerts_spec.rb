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

  it 'should allow a user to subscribe' do
    within_25km && within_150km

    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}&alert=hello"
    fill_in 'alert[email]', :with => 'hello@example.org'
    click_on 'Create alert'

    expect(Mail::TestMailer.deliveries.size).to be 1

    confirmation_link = Mail::TestMailer.deliveries.first.body.to_s.match(/^(http.*)$/, 1)
    visit(confirmation_link)
    expect(page.status_code).to be 200
    expect(page.body).to match(/your alert is now activated/i)
  end

  it 'should mail notifications when new offences are added'
  it 'should not send notifications if the alert is not confirmed'
  it 'should allow a user to unsubscribe' do
    within_25km && within_150km

    # subscribe
    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}&alert=hello"
    fill_in 'alert[email]', :with => 'hello@example.org'
    click_on 'Create alert'

    expect(Mail::TestMailer.deliveries.size).to be 1

    confirmation_link = Mail::TestMailer.deliveries.first.body.to_s.match(/^(http.*)$/, 1)
    visit(confirmation_link)
    expect(page.status_code).to be 200
    expect(page.body).to match(/your alert is now activated/i)

    # unsubscribe
    unsubscribe_link = confirmation_link.to_s.gsub(/confirm/, 'unsubscribe')
    visit(unsubscribe_link)
    expect(page.status_code).to be 200
    expect(page.body).to match(/you have unsubscribed from your alert/i)

  end

  it 'should deny unknown confirmations' do
    visit '/alert/12345/confirm'
    expect(page.status_code).to be 404
  end
end
