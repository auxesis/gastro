RSpec.shared_context 'test data' do
  # morph data
  let(:mocks) { Pathname.new(__FILE__).parent.parent.join('mocks') }
  let(:business_json) { mocks.join('businesses.json').read }
  let(:offence_json) { mocks.join('offences.json').read }

  # tokens
  let(:gastro_reset_token) { Digest::MD5.new.hexdigest(rand(Time.now.to_i).to_s) }
  let(:morph_api_key) { Digest::MD5.new.hexdigest(rand(Time.now.to_i).to_s) }

  # businesses
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
end
