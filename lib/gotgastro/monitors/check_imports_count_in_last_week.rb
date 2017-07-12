module GotGastro
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
        end # def run
      end # class << self
    end # CheckImportsCountInLastWeek
  end # Monitors
end # GotGastro
