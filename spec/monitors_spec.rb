require 'spec_helper'

include GotGastro::Env::Test
include Rack::Test::Methods

describe 'Monitor' do
  describe 'imports' do
    before(:each) { LOG.clear }

    it 'should warn if there were no imports in the last 7 days' do
      GotGastro::Workers::MonitorImports.perform_async
      GotGastro::Workers::MonitorImports.drain
      expect(LOG.grep(/No imports created in the last week/).empty?).to be false
    end

    it 'should print the ids of the import jobs in the last 7 days' do
      count = 3
      count.times { Import.create }
      GotGastro::Workers::MonitorImports.perform_async
      GotGastro::Workers::MonitorImports.drain
      expect(LOG.grep(/There were #{count} imports in the last week/).empty?).to be false
      expect(LOG.grep(/#{Import.map(:id).join(', ')}/).empty?).to be false
    end

    describe 'health check' do
      it 'should expose an ok status', :type => :feature do
        count = 3
        count.times { Import.create }

        visit '/health_checks'
        health_checks = JSON.parse(page.body)
        check_imports = health_checks.find {|check| check['type'] == 'CheckImports'}
        expect(check_imports).to_not be nil
        expect(check_imports['status']).to eq('ok')
      end

      it 'should expose a critical status', :type => :feature do
        visit '/health_checks'
        health_checks = JSON.parse(page.body)
        check_imports = health_checks.find {|check| check['type'] == 'CheckImports'}
        expect(check_imports).to_not be nil
        expect(check_imports['status']).to eq('critical')
      end
    end
  end
end
