require 'spec_helper'

include Rack::Test::Methods

describe 'Location tracking', :type => :feature do
  include_context 'test data'

  it 'should default to Sydney' do
    visit '/search'
    map_url = URI.decode(find('img')['src'])
    expect(map_url).to match('-33.8675,151.207')
  end

  it 'should persist across requests' do
    params = {:path => '/search', :query_values => {:lat => 33.1234, :lng => 150.5678}}
    url = Addressable::URI.new(params).to_s
    visit(url)
    visit '/search'
    map_url = URI.decode(find('img')['src'])
    expect(map_url).to match("#{params[:query_values][:lat]},#{params[:query_values][:lng]}")
  end

  it 'should remember addresses' do
    address = "123 straight street"
    visit "/search?lat=-33.1234&lng=150.5678&address=#{address}"
    visit '/search'
    expect(find('h1').text.include?(address)).to be true
  end
end
