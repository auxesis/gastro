require 'spec_helper'

include Rack::Test::Methods

describe 'Social', :type => :feature do
  include_context 'test data'

  before(:each) do
    set_environment_variable('FB_APP_ID', fb_app_id)
  end

  describe 'detail page' do
    it 'should have a Facebook like button', :aggregate_failures do
      within_25km && within_150km

      urls = Business.limit(10).map(:id).map {|id| '/business/' + id}

      urls.each do |url|
        visit(url)
        fb_like = first(:css, 'div.fb-like')
        expect(fb_like).to_not be nil
        expect(fb_like['data-href']).to eq(current_url)
        expect(fb_like['data-action']).to eq('like')
        expect(fb_like['data-share']).to eq('true')
      end
    end
  end

  describe 'Facebook Open Graph' do
    it 'should have a title and description', :aggregate_failures do
      within_25km && within_150km

      urls = [
        '/',
        "/search?lat=#{origin.lat}&lng=#{origin.lng}",
        "/business/#{Business.first.id}",
        '/about',
        '/privacy',
        '/report',
      ]

      urls.each do |url|
        visit(url)
        og_title = first(:xpath, "//meta[@property='og:title']", :visible => false)
        expect(og_title).to_not eq(nil), "missing og:title at #{url}"
        og_description = first(:xpath, "//meta[@property='og:description']", :visible => false)
        expect(og_description).to_not eq(nil), "missing og:description at #{url}"
      end
    end

    it 'should link to the canonical URL', :aggregate_failures do
      within_25km && within_150km

      urls = [
        '/',
        "/search?lat=#{origin.lat}&lng=#{origin.lng}",
        "/business/#{Business.first.id}",
        '/about',
        '/privacy',
        '/report',
      ]

      urls.each do |url|
        visit(url)
        og_url = first(:xpath, "//meta[@property='og:url']", :visible => false)
        expect(og_url).to_not eq(nil), "missing og:url at #{url}"
        expect(og_url['content']).to eq(page.current_url)
      end
    end

    it 'should have an image', :aggregate_failures do
      within_25km && within_150km

      urls = [
        '/',
        '/about',
        '/privacy',
        '/report',
      ]

      urls.each do |url|
        visit(url)
        og_image = first(:xpath, "//meta[@property='og:image']", :visible => false)
        expect(og_image).to_not eq(nil), "missing og:image at #{url}"
        expect(og_image['content']).to match('/img/apple-touch-icon-precomposed.png')
      end
    end

    it 'should have a map image if search or business result', :aggregate_failures do
      within_25km && within_150km

      urls = [
        "/search?lat=#{origin.lat}&lng=#{origin.lng}",
        "/business/#{Business.first.id}",
      ]

      urls.each do |url|
        visit(url)
        og_image = first(:xpath, "//meta[@property='og:image']", :visible => false)
        expect(og_image).to_not eq(nil), "missing og:image at #{url}"
        expect(og_image['content']).to match('https://maps.googleapis.com/maps/api/staticmap')
      end
    end

    it 'should have a Facebook App ID', :aggregate_failures do
      within_25km && within_150km

      urls = [
        '/',
        "/search?lat=#{origin.lat}&lng=#{origin.lng}",
        "/business/#{Business.first.id}",
        '/about',
        '/privacy',
        '/report',
      ]

      urls.each do |url|
        visit(url)
        fb_app_id = first(:xpath, "//meta[@property='fb:app_id']", :visible => false)
        expect(fb_app_id).to_not eq(nil), "missing fb:app_id at #{url}"
      end
    end
  end

  describe 'Twitter' do
    it 'should have a title, description, and site', :aggregate_failures do
      within_25km && within_150km

      urls = [
        '/',
        "/search?lat=#{origin.lat}&lng=#{origin.lng}",
        "/business/#{Business.first.id}",
        '/about',
        '/privacy',
        '/report',
      ]

      urls.each do |url|
        visit(url)
        twitter_title = first(:xpath, "//meta[@name='twitter:title']", :visible => false)
        expect(twitter_title).to_not eq(nil), "missing twitter:title at #{url}"
        twitter_description = first(:xpath, "//meta[@name='twitter:description']", :visible => false)
        expect(twitter_description).to_not eq(nil), "missing twitter:description at #{url}"
        twitter_site = first(:xpath, "//meta[@name='twitter:site']", :visible => false)
        expect(twitter_site).to_not eq(nil), "missing twitter:site at #{url}"
      end
    end

    it 'should have an image', :aggregate_failures do
      within_25km && within_150km

      urls = [
        '/',
        '/about',
        '/privacy',
        '/report',
      ]

      urls.each do |url|
        visit(url)

        twitter_image = first(:xpath, "//meta[@name='twitter:image']", :visible => false)
        expect(twitter_image).to_not eq(nil), "missing twitter:image at #{url}"
        expect(twitter_image['content']).to match('/img/apple-touch-icon-precomposed.png')

        twitter_card = first(:xpath, "//meta[@name='twitter:card']", :visible => false)
        expect(twitter_card).to_not eq(nil), "missing twitter:card at #{url}"
        expect(twitter_card['content']).to eq('summary')
      end
    end

    it 'should have a map image if search or business result', :aggregate_failures do
      within_25km && within_150km

      urls = [
        "/search?lat=#{origin.lat}&lng=#{origin.lng}",
        "/business/#{Business.first.id}",
      ]

      urls.each do |url|
        visit(url)

        twitter_image = first(:xpath, "//meta[@name='twitter:image']", :visible => false)
        expect(twitter_image).to_not eq(nil), "missing twitter:image at #{url}"
        expect(twitter_image['content']).to match('https://maps.googleapis.com/maps/api/staticmap')

        twitter_card = first(:xpath, "//meta[@name='twitter:card']", :visible => false)
        expect(twitter_card).to_not eq(nil), "missing twitter:card at #{url}"
        expect(twitter_card['content']).to eq('summary_large_image')
      end
    end
  end
end
