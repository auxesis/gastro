module Gastro
  class App < Sinatra::Base
    get '/' do
      "hello spoons"
    end
  end
end
