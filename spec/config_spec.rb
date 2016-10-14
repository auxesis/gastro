require 'spec_helper'

include Rack::Test::Methods
include GotGastro::Env::Test

describe 'Config', :type => :feature do
  include_context 'test data'

  before(:each) do
    set_environment_variable('GASTRO_RESET_TOKEN', gastro_reset_token)
    set_environment_variable('MORPH_API_KEY', morph_api_key)
  end

  it 'should expose config sourced from environment variables' do
    expect(config['settings']['reset_token']).to eq(gastro_reset_token)
    expect(config['settings']['morph_api_key']).to eq(morph_api_key)
  end

  it 'should error if config is not set' do
    expect {
      delete_environment_variable('GASTRO_RESET_TOKEN')
      delete_environment_variable('MORPH_API_KEY')
      config
    }.to raise_error(ArgumentError)
  end

  it 'should continue to error if config is not set' do
    expect {
      delete_environment_variable('GASTRO_RESET_TOKEN')
      delete_environment_variable('MORPH_API_KEY')
      config
    }.to raise_error(ArgumentError)

    expect {
      delete_environment_variable('GASTRO_RESET_TOKEN')
      delete_environment_variable('MORPH_API_KEY')
      config
    }.to raise_error(ArgumentError)
  end

end
