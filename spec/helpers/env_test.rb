module GotGastro
  module Env
    module Test
      def restore_env
        ENV.replace(@original) if @original
        @original = nil
      end

      def delete_environment_variable(name)
        @original ||= ENV.to_hash
        ENV.delete(name)
      end

      def set_environment_variable(name, value)
        @original ||= ENV.to_hash
        ENV[name] = value
      end
    end
  end
end
