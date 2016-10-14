require 'spec_helper'

include Rack::Test::Methods
include Mail::Matchers

describe 'Alerts', :type => :feature do
  include_context 'test data'

  let(:subscribed_user) {
    within_25km && within_150km

    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}&alert=hello"
    fill_in 'alert[email]', :with => 'hello@example.org'
    click_on 'Create alert'
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 1

    mail = Mail::TestMailer.deliveries.pop
    confirmation_link = mail.body.to_s.match(/^(http.*)$/, 1).to_s
    expect(confirmation_link).to be_url
    visit(confirmation_link)
    expect(page.status_code).to be 200
    expect(page.body).to match(/your alert is now activated/i)

    { :alert => Alert.first, :confirmation_link => confirmation_link }
  }

  before(:each) do
    Mail::TestMailer.deliveries.clear
  end

  it 'should allow a user to subscribe' do
    subscribed_user
  end

  it 'should deny unknown confirmations' do
    visit '/alert/12345/confirm'
    expect(page.status_code).to be 404
  end

  it 'should send notifications when new offences are added' do
    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key=.*&query=select%20\*%20from%20'businesses'}
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'offences'}
      ).to_return(:status => 200, :body => new_offence_json)

    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)

    alert = subscribed_user[:alert]

    before = Offence.count
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    after = Offence.count
    expect(before).to be < after

    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 1
    alert_mail = Mail::TestMailer.deliveries.first

    expect(alert_mail).to_not be nil
    expect(alert_mail.to).to eq([alert.email])

    businesses = Business.find_near(alert.location, :within => alert.distance)
    conditions = { :created_at => Time.now.beginning_of_day..Time.now.end_of_day }
    offences = Offence.join(businesses, :id => :business_id).where(conditions).all

    expect(alert_mail.subject).to match(alert.address)
    expect(alert_mail.subject).to match(/^#{offences.size} new food safety warnings/)
    expect(alert_mail.body).to match(alert.address)
    expect(alert_mail.body).to match(alert.distance.to_s)
    expect(alert_mail.body).to match('unsubscribe')

    expect(alert_mail.body.to_s.scan(/(?=Business)/).count).to be(offences.size)
    expect(alert_mail.body.to_s.scan(/(?=Address)/).count).to be(offences.size)
    expect(alert_mail.body.to_s.scan(/(?=Date)/).count).to be(offences.size)
    expect(alert_mail.body.to_s.scan(/(?=Description)/).count).to be(offences.size)
  end

  it 'should not send notifications if the alert is not confirmed'
  it 'should not send notifications if the alert is unsubscribed'

  it 'should allow a user to unsubscribe' do
    # FIXME(auxesis) this is a smell. We should be getting the unsubscribe link
    # from an alert email.
    confirmation_link = subscribed_user[:confirmation_link]
    unsubscribe_link  = confirmation_link.to_s.gsub(/confirm/, 'unsubscribe')

    # unsubscribe
    visit(unsubscribe_link)
    expect(page.status_code).to be 200
    expect(page.body).to match(/you have unsubscribed from your alert/i)
  end

  it 'should deny unknown unsubscribes' do
    visit '/alert/12345/unsubscribe'
    expect(page.status_code).to be 404
  end

end
