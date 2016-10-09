web: bundle exec puma -e production -p $PORT -S ~/puma
sidekiq: bundle exec sidekiq -c 2 -v -r ./lib/gotgastro/workers.rb
