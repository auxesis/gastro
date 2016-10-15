require 'spec_helper'

include Rack::Test::Methods

describe 'Location tracking', :type => :feature do
  it 'should default to Sydney' do
    visit '/search'
    expect(find('img')['src'].include?('-33.8675,151.207')).to be true
  end

  it 'should persist across requests' do
    visit '/search?lat=-33.1234&lng=150.5678'
    visit '/search'
    expect(find('img')['src'].include?('-33.1234,150.5678')).to be true
  end

  it 'should remember addresses' do
    address = "123 straight street"
    visit "/search?lat=-33.1234&lng=150.5678&address=#{address}"
    visit '/search'
    expect(find('h1').text.include?(address)).to be true
  end
end
