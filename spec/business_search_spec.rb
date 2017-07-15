require 'spec_helper'

include Rack::Test::Methods

describe 'Business', :type => :feature do
  include_context 'test data'

  describe 'search' do
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

    it "shouldn't genenerate img urls longer than 2000 characters" do
      thousands_of_results

      visit "/search?lat=#{origin.lat}&lng=#{origin.lng}"

      expect(find('img')['src'].size).to be <= 2000
    end
  end

  describe 'show' do
    it 'should show detail on individual businesses' do
      within_25km && within_150km

      visit "/search?lat=#{origin.lat}&lng=#{origin.lng}&address=#{origin.address}"

      detail_link = all('div.result a').map {|a| a['href']}.first
      expect(detail_link).to_not be nil

      visit(detail_link)

      search_link = all('div.row.nav a').map {|a| a['href']}.first
      expect(search_link).to_not be nil

      query = URI.decode(URI.parse(search_link).query)
      expect(query).to include(origin.address)
      expect(query).to include(origin.lat.to_s)
      expect(query).to include(origin.lng.to_s)
    end

    it 'should handle a business not existing' do
      visit '/business/aoesntaoesnaotesnaoetasonetsaonet'
      expect(status_code).to be 404
    end
  end
end
