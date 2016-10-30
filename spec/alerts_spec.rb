require 'spec_helper'
require 'faker'

include Rack::Test::Methods
include Mail::Matchers

describe 'Alerts', :type => :feature do
  include_context 'test data'

  before(:each) do
    Mail::TestMailer.deliveries.clear
  end

  it 'should allow a user to subscribe' do
    subscribed_user
  end

  describe 'should validate' do
    it 'has an email' do
      within_25km && within_150km

      # Create it at /search
      visit "/search?lat=#{origin.lat}&lng=#{origin.lng}&address=foobar"
      click_on 'Create alert'
      expect(page.status_code).to be 400
      expect(page.body).to match(/there was a problem creating your alert/i)
      expect(page.body).to match(/we need a valid email address/i)

      GotGastro::Workers::EmailWorker.drain
      expect(Mail::TestMailer.deliveries.size).to be 0

      # Try to create, but with invalid input
      fill_in 'alert[email]', :with => 'aoesntoasnetaoesntoaesnatoesnaote'
      click_on 'Create alert'
      expect(page.status_code).to be 400
      expect(page.body).to match(/there was a problem creating your alert/i)
      expect(page.body).to match(/we need a valid email address/i)

      GotGastro::Workers::EmailWorker.drain
      expect(Mail::TestMailer.deliveries.size).to be 0

      # Create with valid input
      fill_in 'alert[email]', :with => 'me@example.com'
      click_on 'Create alert'
      expect(page.status_code).to be 200
      expect(page.body).to match(/now check your email/i)

      GotGastro::Workers::EmailWorker.drain
      expect(Mail::TestMailer.deliveries.size).to be 1
    end
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
      ).to_return(:status => 200, :body => offence_json)

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

    expect(Mail::TestMailer.deliveries.size).to eq(1)
    alert_mail = Mail::TestMailer.deliveries.pop
    expect(alert_mail.to).to eq([alert.email])

    businesses = Business.find_near(alert.location, :within => alert.distance)
    conditions = { Sequel.qualify(:offences, :created_at) => Time.now.beginning_of_day..Time.now.end_of_day }
    offences = Offence.join(businesses, :id => :business_id).where{conditions}.all

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

  it 'should allow a user to unsubscribe' do
    unsubscribed_user
  end

  it 'should deny unknown unsubscribes' do
    visit '/alert/12345/unsubscribe'
    expect(page.status_code).to be 404
  end

  it 'should not send notifications if the alert is not confirmed' do
    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key=.*&query=select%20\*%20from%20'businesses'}
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'offences'}
      ).to_return(:status => 200, :body => offence_json)

    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)

    unconfirmed_user && subscribed_user

    before = Offence.count
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    after = Offence.count
    expect(before).to be < after

    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 1
  end

  it 'should not send notifications if the alert is unsubscribed' do
    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key=.*&query=select%20\*%20from%20'businesses'}
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'offences'}
      ).to_return(:status => 200, :body => offence_json)

    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)

    unconfirmed_user && subscribed_user && unsubscribed_user

    before = Offence.count
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    after = Offence.count
    expect(before).to be < after

    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 1
  end

  it 'should not send notifications if there are no new offences' do
    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key=.*&query=select%20\*%20from%20'businesses'}
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'offences'}
      ).to_return(:status => 200, :body => offence_json)

    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)

    subscribed_user

    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 1
    Mail::TestMailer.deliveries.clear

    time_travel_to('tomorrow')

    # import same data the next day
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 0
  end


  it 'should not send repeat notifications for the same offence' do
    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key=.*&query=select%20\*%20from%20'businesses'}
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'offences'}
      ).to_return(:status => 200, :body => offence_json)

    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)

    subscribed_user

    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 1
    Mail::TestMailer.deliveries.clear

    # import same data rn, to trigger another send
    visit "/reset?token=#{gastro_reset_token}"
    visit "/reset?token=#{gastro_reset_token}"
    visit "/reset?token=#{gastro_reset_token}"
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 0
  end

  it 'should allow changing the alert distance' do
    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key=.*&query=select%20\*%20from%20'businesses'}
      ).to_return(:status => 200, :body => business_json)

    stub_request(:get,
      %r{https://api\.morph\.io/auxesis/gotgastro_scraper/data\.json\?key.*&query=select%20\*%20from%20'offences'}
      ).to_return(:status => 200, :body => offence_json).then.
        to_return(lambda { |request| {:body => offence_json_generator(:count => 20, :within => 15)} })

    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)

    alert = subscribed_user[:alert]

    # first
    # trigger import
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    # look at received mail
    expect(Mail::TestMailer.deliveries.size).to be 1
    alert_mail = Mail::TestMailer.deliveries.pop
    expect(alert_mail.to).to eq([alert.email])

    # change the size
    edit_link = alert_mail.body.to_s.match(/(http.*edit)$/, 1).to_s
    visit(edit_link)
    choose('15km')
    click_on 'Update size'



    time_travel_to('tomorrow')

    # second
    # trigger import
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    # look at received mail
    expect(Mail::TestMailer.deliveries.size).to be 1
    alert_mail = Mail::TestMailer.deliveries.pop

    expect(alert_mail.to).to eq([alert.email])
    distances = alert_mail.body.to_s.split("\n").grep(/^Distance away: /).map {|d| d[/ (\d\.\d\d)km$/, 1].to_f}
    expect(distances.size).to be > 0
    distances.each do |distance|
      expect(distance).to be < 15
    end

    time_travel_to('tomorrow')

    # third
    # trigger import
    visit "/reset?token=#{gastro_reset_token}"
    GotGastro::Workers::Import.drain
    expect(GotGastro::Workers::EmailAlerts.jobs.size).to be > 0

    GotGastro::Workers::EmailAlerts.drain
    GotGastro::Workers::EmailWorker.drain

    # look at received mail
    expect(Mail::TestMailer.deliveries.size).to eq(1)
    alert_mail = Mail::TestMailer.deliveries.pop

    expect(alert_mail.to).to eq([alert.email])
    distances = alert_mail.body.to_s.split("\n").grep(/^Distance away: /).map {|d| d[/ (\d\.\d\d)km$/, 1].to_f}
    expect(distances.size).to be > 0
    distances.each do |distance|
      expect(distance).to be < 15
    end
  end
end
