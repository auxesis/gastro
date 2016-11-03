require 'spec_helper'
require 'faker'

include Rack::Test::Methods

describe 'CDN', :type => :feature do
  include_context 'test data'

  let(:cdn_base) { "https://" + Faker::Internet.domain_name }

  before(:each) do
    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)
  end

  it 'should cache static pages' do
    urls = [
      '/',
      '/about',
      '/privacy',
      '/report',
    ]
    urls.each do |url|
      visit(url)
      expect(page.response_headers).to include('Cache-Control')
    end
  end

  def params(attrs)
    q = Addressable::URI.new.query_values = attrs
    q.to_query
  end

  it 'should privately cache correctly', js: true do
    WebMock.disable_net_connect!(allow_localhost: true)
    within_25km && within_150km

    # first search
    visit "/search?lat=#{origin.lat}&lng=#{origin.lng}"
    detail_link = all('div.result a').map {|a| a['href']}.first
    expect(detail_link).to_not be nil
    visit(detail_link)
    first_distance_away = first('div.alert.alert-info').text

    # second search
    query = params({
      :lat => origin.lat - 0.01,
      :lng => origin.lng - 0.01
    })
    visit "/search?#{query}"
    visit(detail_link)
    second_distance_away = first('div.alert.alert-info').text

    expect(first_distance_away).to_not eq(second_distance_away)
  end

  describe 'enabled' do
    it 'should serve JavaScript from a CDN' do
      set_environment_variable('CDN_BASE', cdn_base)

      visit '/'

      doc = Nokogiri::HTML(page.body)
      scripts = doc.search('script').map { |tag| tag.attributes['src'].value }
      scripts.each do |value|
        next if value =~ /maps.googleapis.com/
        expect(value).to match(/^#{cdn_base}/)
      end
    end

    it 'should serve CSS from a CDN' do
      set_environment_variable('CDN_BASE', cdn_base)

      visit '/'

      doc = Nokogiri::HTML(page.body)
      links = doc.search("//link[@type='text/css']").map do |tag|
        tag.attributes['href'].value
      end
      links.each do |value|
        expect(value).to match(/^#{cdn_base}/)
      end
    end

    it 'should set up headers for CORS' do
      filenames = Pathname.glob(root + 'lib' + 'gotgastro' + 'public' + 'css' + 'vendor' + 'fonts' + '*')
      fonts = filenames.map {|font| '/css/vendor/fonts/' + font.basename.to_s }

      fonts.each do |url|
        visit(url)
        expect(page.response_headers).to include('Access-Control-Allow-Origin')
      end
    end

    it 'should serve images from a CDN' do
      set_environment_variable('CDN_BASE', cdn_base)

      visit '/'

      doc = Nokogiri::HTML(page.body)
      icons = doc.search('//link').select { |l|
        l.attributes['rel'].value =~ /icon/
      }.map {|l|
        l.attributes['href'].value
      }

      icons.each do |value|
        expect(value).to match(/^#{cdn_base}/)
      end
    end
  end

  describe 'disabled' do
    it 'should not serve JavaScript from a CDN' do
      delete_environment_variable('CDN_BASE')

      visit '/'

      doc = Nokogiri::HTML(page.body)
      scripts = doc.search('script').map { |tag| tag.attributes['src'].value }
      scripts.each do |value|
        next if value =~ /maps.googleapis.com/
        expect(value).to_not match(/^#{cdn_base}/)
      end
    end

    it 'should not serve CSS from a CDN' do
      delete_environment_variable('CDN_BASE')

      visit '/'

      doc = Nokogiri::HTML(page.body)
      links = doc.search("//link[@type='text/css']").map do |tag|
        tag.attributes['href'].value
      end
      links.each do |value|
        expect(value).to_not match(/^#{cdn_base}/)
      end
    end

    it 'should not serve images from a CDN' do
      delete_environment_variable('CDN_BASE')

      visit '/'

      doc = Nokogiri::HTML(page.body)
      icons = doc.search('//link').select { |l|
        l.attributes['rel'].value =~ /icon/
      }.map {|l|
        l.attributes['href'].value
      }

      icons.each do |value|
        expect(value).to_not match(/^#{cdn_base}/)
      end
    end
  end
end
