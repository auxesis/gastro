require 'faker'

RSpec.shared_context 'test data' do
  # morph data
  let(:mocks) { Pathname.new(__FILE__).parent.parent.join('mocks') }
  let(:business_json) { mocks.join('businesses.json').read }
  let(:offence_json) { mocks.join('offences.json').read }
  let(:new_offence_json) { mocks.join('new_offences.json').read }

  # tokens
  let(:gastro_reset_token) { Digest::MD5.new.hexdigest(rand(Time.now.to_i).to_s) }
  let(:morph_api_key) { Digest::MD5.new.hexdigest(rand(Time.now.to_i).to_s) }
  let(:fb_app_id) { Digest::MD5.new.hexdigest(rand(Time.now.to_i).to_s) }

  # businesses
  let(:origin) {
    Business.new(:lat => -33.1234, :lng => 150.5678, :address => '123 Straight St, Burwood')
  }
  let(:within_25km) {
    lats = (1..16).map {|i| origin.lat + i * 0.01 }
    lngs = (1..16).map {|i| origin.lng + i * 0.01 }

    lats.zip(lngs).each_with_index do |(lat, lng), i|
      name = Faker::Name.name_with_middle
      business = Business.create(:name => name, :lat => lat, :lng => lng)
      make_offences(:for => business, :count => 1)
    end
  }
  let(:within_150km) {
    lats = (1..16).map {|i| origin.lat + i * 0.1 }
    lngs = (1..16).map {|i| origin.lng + i * 0.1 }

    lats.zip(lngs).each do |lat, lng|
      name = Faker::Name.name_with_middle
      business = Business.create(:name => name, :lat => lat, :lng => lng)
      make_offences(:for => business, :count => 3)
    end
  }
  let(:between_25km_and_150km) {
    lats = (3..16).map {|i| origin.lat + i * 0.1 }
    lngs = (3..16).map {|i| origin.lng + i * 0.1 }

    lats.zip(lngs).each do |lat, lng|
      name = Faker::Name.name_with_middle
      business = Business.create(:name => name, :lat => lat, :lng => lng)
      make_offences(:for => business, :count => 1)
    end
  }
  let(:thousands_of_results) {
    lats = (1..1000).map {|i| origin.lat + i * 0.0001 }
    lngs = (1..1000).map {|i| origin.lng + i * 0.0001 }

    lats.zip(lngs).each do |lat, lng|
      name     = Faker::Name.name_with_middle
      business = Business.create(:name => name, :lat => lat, :lng => lng)
      make_offences(:for => business, :count => 1)
    end
  }
  let(:some_prosecutions) {
    Business.limit(Business.count / 4).each do |business|
      make_offences(:for => business, :count => 1, :severity => 'major')
    end
  }
  let(:subscribed_user) {
    within_25km && within_150km

    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}&address=foobar"
    fill_in 'alert[email]', :with => 'subscribed@example.org'
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

  let(:unconfirmed_user) {
    within_25km && within_150km

    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}&address=foobar"
    fill_in 'alert[email]', :with => 'unconfirmed@example.org'
    click_on 'Create alert'
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 1
    Mail::TestMailer.deliveries.pop
  }

  let(:unsubscribed_user) {
    within_25km && within_150km

    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}&address=foobar"
    fill_in 'alert[email]', :with => 'unsubscribed@example.org'
    click_on 'Create alert'
    GotGastro::Workers::EmailWorker.drain

    expect(Mail::TestMailer.deliveries.size).to be 1

    mail = Mail::TestMailer.deliveries.pop
    confirmation_link = mail.body.to_s.match(/^(http.*)$/, 1).to_s
    expect(confirmation_link).to be_url
    visit(confirmation_link)
    expect(page.status_code).to be 200
    expect(page.body).to match(/your alert is now activated/i)

    # unsubscribe
    unsubscribe_link = confirmation_link.to_s.gsub(/confirm/, 'unsubscribe')
    visit(unsubscribe_link)
    expect(page.status_code).to be 200
    expect(page.body).to match(/you have unsubscribed from your alert/i)
  }

  def make_offences(opts={})
    options = { :count => 1, :severity => 'minor' }.merge(opts)
    raise ArgumentError unless options[:for]
    business = options[:for]

    options[:count].times do |i|
      attrs = {
        'business_id' => business.id,
        'date' => Faker::Time.backward(14).to_date,
        'link' => Faker::Internet.url('www2.health.vic.gov.au/public-health/food-safety/convictions-register'),
        'description' => Faker::ChuckNorris.fact,
        'severity' => options[:severity],
      }
      Offence.create(attrs)
    end
  end

  def offence_json_generator(opts={})
    options = {
      :count => 10,
      :within => 15,
      :origin => origin,
    }.merge(opts)

    business_ids = Business.find_near(origin, :within => options[:within], :limit => nil).map(:id)

    offences = (0..options[:count]).map { |i|
      {
        'business_id' => i >= business_ids.size ? business_ids[0] : business_ids[i],
        'date' => Faker::Time.backward(14).to_date,
        'link' => Faker::Internet.url('www2.health.vic.gov.au/public-health/food-safety/convictions-register'),
        'description' => Faker::ChuckNorris.fact,
      }
    }

    offences.to_json
  end

end
