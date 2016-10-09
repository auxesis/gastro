require 'sidekiq'
require 'redis'
require 'sidekiq/api'
require 'mail'

module GotGastro
  module Workers
    class EmailWorker
      include Sidekiq::Worker

      def perform(mail)
        message = Mail.new(mail)
        message.deliver
      end
    end
  end
end
