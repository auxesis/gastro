module GotGastro
  module Monitors
    class CheckLastImportStatus
      class << self
        attr_reader :status, :message, :type

        def run
          @type = self.to_s.split('::').last

          import = ::Import.last

          if import
            if import.duration > 0
              @status  = :ok
              @message = "Last import (##{import.id}, starting at #{import.created_at}) ran for #{import.duration} seconds"
            else
              @status  = :critical
              @message = "Last import (##{import.id}, starting at #{import.created_at}) failed with status #{import.duration}"
            end
          else
            @status  = :critical
            @message = 'No import has been run yet'
          end
        end # def run
      end # class << self
    end # CheckLastImportStatus
  end # Monitors
end # GotGastro
