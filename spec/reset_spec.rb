require 'spec_helper'

include Rack::Test::Methods

describe 'Data reset', :type => :feature do
  it 'should create records' do
    before = Business.count
    visit '/reset'
    after = Business.count

    expect(after).to be > before
  end

  it 'should create associations' do
    visit '/reset'

    Business.each do |biz|
      expect(biz.offences.size).to be > 0
    end
  end
end
