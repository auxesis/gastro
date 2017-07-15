require 'spec_helper'

include Rack::Test::Methods
include GotGastro::Env::Test

describe 'Config', :type => :feature do
  include_context 'test data'

  before(:each) do
    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)
  end

  after(:each) do
    config.reset!
    LOG.clear
  end

  it 'should expose config sourced from environment variables' do
    expect(config.gastro_reset_token).to eq(gastro_reset_token)
    expect(config.morph_api_key).to eq(morph_api_key)
  end

  it 'should warn if config is not set' do
    delete_environment_variable('GASTRO_RESET_TOKEN')
    delete_environment_variable('MORPH_API_KEY')
    config
    expect(LOG.find {|l| l =~ /Warning:.*GASTRO_RESET_TOKEN/}).to_not be nil
    expect(LOG.find {|l| l =~ /Warning:.*MORPH_API_KEY/}).to_not be nil
  end
end
