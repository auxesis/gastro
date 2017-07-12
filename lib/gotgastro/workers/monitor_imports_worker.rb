require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'gotgastro/monitors'

module GotGastro
  module Workers
    class MonitorImports
      include Sidekiq::Worker

      def perform
        check = GotGastro::Monitors::CheckImportsCountInLastWeek
        check.run
        info("#{check.type}: #{check.status}: #{check.message}")
      end
    end # MonitorImports
  end # Workers
end # GotGastro
