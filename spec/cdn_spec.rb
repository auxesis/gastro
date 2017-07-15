require 'spec_helper'
require 'faker'

include Rack::Test::Methods

describe 'CDN', :type => :feature do
  include_context 'test data'

  let(:cdn_base) { "https://" + Faker::Internet.domain_name }

  it 'should cache static pages' do
    urls = [
      '/',
      '/about',
      '/privacy',
      '/report',
    ]
    urls.each do |url|
      visit(url)
      expect(page.response_headers['Cache-Control']).to eq('public, max-age=86400')
    end
  end

  describe 'enabled' do
    it 'should serve JavaScript from a CDN', :aggregate_failures do
      set_environment_variable('CDN_BASE', cdn_base)

      visit '/'

      doc = Nokogiri::HTML(page.body)
      scripts = doc.search('script').map { |tag| tag.attributes['src'].value }
      scripts.reject! {|script| script =~ /maps.googleapis.com/}

      expect(scripts.size).to be > 0
      scripts.each { |value| expect(value).to match(/^#{cdn_base}/) }
    end

    it 'should serve CSS from a CDN', :aggregate_failures do
      set_environment_variable('CDN_BASE', cdn_base)

      visit '/'

      doc = Nokogiri::HTML(page.body)
      links = doc.search("//link[@type='text/css']").map { |tag| tag.attributes['href'].value }

      expect(links.size).to be > 0
      links.each { |value| expect(value).to match(/^#{cdn_base}/) }
    end

    it 'should set up headers for CORS', :aggregate_failures do
      filenames = Pathname.glob(root + 'lib' + 'gotgastro' + 'public' + 'css' + 'vendor' + 'fonts' + '*')
      fonts = filenames.map {|font| '/css/vendor/fonts/' + font.basename.to_s }

      fonts.each do |url|
        visit(url)
        expect(page.response_headers).to include('Access-Control-Allow-Origin')
      end
    end

    it 'should serve images from a CDN', :aggregate_failures do
      set_environment_variable('CDN_BASE', cdn_base)

      visit '/'

      doc = Nokogiri::HTML(page.body)
      icons = doc.search('//link').select { |l|
        l.attributes['rel'].value =~ /icon/
      }.map {|l|
        l.attributes['href'].value
      }

      expect(icons.size).to be > 0
      icons.each { |value| expect(value).to match(/^#{cdn_base}/) }
    end
  end

  describe 'disabled' do
    it 'should not serve JavaScript from a CDN', :aggregate_failures do
      delete_environment_variable('CDN_BASE')

      visit '/'

      doc = Nokogiri::HTML(page.body)
      scripts = doc.search('script').map { |tag| tag.attributes['src'].value }
      scripts.reject! {|script| script =~ /maps.googleapis.com/}

      expect(scripts.size).to be > 0
      scripts.each { |value| expect(value).to_not match(/^#{cdn_base}/) }
    end

    it 'should not serve CSS from a CDN', :aggregate_failures do
      delete_environment_variable('CDN_BASE')

      visit '/'

      doc = Nokogiri::HTML(page.body)
      links = doc.search("//link[@type='text/css']").map do |tag|
        tag.attributes['href'].value
      end

      expect(links.size).to be > 0
      links.each { |value| expect(value).to_not match(/^#{cdn_base}/) }
    end

    it 'should not serve images from a CDN', :aggregate_failures do
      delete_environment_variable('CDN_BASE')

      visit '/'

      doc = Nokogiri::HTML(page.body)
      icons = doc.search('//link').select { |l|
        l.attributes['rel'].value =~ /icon/
      }.map {|l|
        l.attributes['href'].value
      }

      expect(icons.size).to be > 0
      icons.each { |value| expect(value).to_not match(/^#{cdn_base}/) }
    end
  end
end
