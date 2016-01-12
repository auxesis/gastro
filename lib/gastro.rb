module Gastro
  class App < Sinatra::Base
    set :root, Pathname.new(__FILE__).parent

    get '/' do
      haml :index
    end

    get '/results' do
      haml :results
    end

    get '/detail' do
      haml :detail
    end
  end
end
