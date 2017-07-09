require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'rest-client'

module GotGastro
  module Workers
    class MonitorImports
      include Sidekiq::Worker

      def perform
        check = GotGastro::Monitors::CheckImports
        check.run
        info("#{check.type}: #{check.status}: #{check.message}")
      end
    end
  end

  module Monitors
    class CheckImports
      class << self
        attr_reader :status, :message, :type

        def run
          @type = self.to_s.split('::').last

          imports = ::Import.where(:created_at => 1.week.ago..Time.now).all

          if imports.empty?
            @status  = :critical
            @message = 'No imports created in the last week'
          else
            @status  = :ok
            @message = "There were #{imports.size} imports in the last week: #{imports.map(&:id).join(', ')}"
          end
        end
      end
    end
  end
end
