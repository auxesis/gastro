require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'rest-client'

module GotGastro
  module Workers
    class MonitorImports
      include Sidekiq::Worker

      def perform
        check = GotGastro::Monitors::CheckImportsCountInLastWeek
        check.run
        info("#{check.type}: #{check.status}: #{check.message}")
      end
    end
  end

  module Monitors
    class CheckImportsCountInLastWeek
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

    class CheckLastImportStatus
      class << self
        attr_reader :status, :message, :type

        def run
          @type = self.to_s.split('::').last

          import = ::Import.last

          if import
            if import.duration > 0
              @status  = :ok
              @message = "Last import (##{import.id}) ran for #{import.duration} seconds"
            else
              @status  = :critical
              @message = "Last import (##{import.id}) failed with status #{import.duration}"
            end
          else
            @status  = :critical
            @message = 'No import has been run yet'
          end
        end
      end
    end
  end
end
