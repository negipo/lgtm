require 'rack'
require './app'

if memcache_servers = ENV["MEMCACHE_SERVERS"]
  if ENV['DEVELOPMENT']
    use Rack::Cache,
      verbose: true,
      metastore:   "memcached://#{memcache_servers}",
      entitystore: "memcached://#{memcache_servers}"
  else
    use Rack::Cache,
      verbose: true,
      metastore:   "memcached://#{memcache_servers}",
      entitystore: "memcached://#{memcache_servers}"
  end
end

run Sinatra::Application
