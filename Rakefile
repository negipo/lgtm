require 'bundler/setup'
Bundler.require
require './lib/cache_configuration'

task :clear_cache do
  desc 'clear cache'
  CacheConfiguration.client.flush
  puts 'clear cache'
end
