require 'spec_helper'

include Rack::Test::Methods

describe 'Business search', :type => :feature do
  let(:origin) { Business.new(:lat => -33.1234, :lng => 150.5678) }
  let(:within_25km) {
    lats = (1..16).map {|i| origin.lat + i * 0.01 }
    lngs = (1..16).map {|i| origin.lng + i * 0.01 }

    lats.zip(lngs).each do |lat, lng|
      Business.create(:name => "#{lat},#{lng}", :lat => lat, :lng => lng)
    end
  }
  let(:within_150km) {
    lats = (1..16).map {|i| origin.lat + i * 0.1 }
    lngs = (1..16).map {|i| origin.lng + i * 0.1 }

    lats.zip(lngs).each do |lat, lng|
      Business.create(:name => "#{lat},#{lng}", :lat => lat, :lng => lng)
    end
  }
  let(:between_25km_and_150km) {
    lats = (3..16).map {|i| origin.lat + i * 0.1 }
    lngs = (3..16).map {|i| origin.lng + i * 0.1 }

    lats.zip(lngs).each do |lat, lng|
      Business.create(:name => "#{lat},#{lng}", :lat => lat, :lng => lng)
    end
  }
  let(:thousands_of_results) {
    lats = (1..1000).map {|i| origin.lat + i * 0.0001 }
    lngs = (1..1000).map {|i| origin.lng + i * 0.0001 }

    lats.zip(lngs).each do |lat, lng|
      Business.create(:name => "#{lat},#{lng}", :lat => lat, :lng => lng)
    end
  }

  it 'should only show results in the surrounding 25km' do
    within_25km && within_150km

    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}"

    expect(all('div.result div.distance').size).to be > 0
    distances = all('div.result div.distance').map do |div|
      div.text[/(.*)km/, 1].to_f
    end

    expect(distances.max).to be <= 25.0
  end

  it 'should gracefully handle no results' do
    between_25km_and_150km

    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}"

    expect(all('div.result div.distance').size).to be 0
  end

  it 'should handle a business not existing' do
    visit '/business/aoesntaoesnaotesnaoetasonetsaonet'
    expect(status_code).to be 404
  end

  it "shouldn't genenerate img urls longer than 2000 characters" do
    thousands_of_results

    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}"

    expect(find('img')['src'].size).to be <= 2000
  end
end
