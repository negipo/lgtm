require 'rack'
require './app'

memcache_servers = ENV["MEMCACHE_SERVERS"]
if memcache_servers
  client = Dalli::Client.new(
    memcache_servers,
    value_max_bytes: 10485760
  )
  use Rack::Cache, verbose: true, metastore: client, entitystore: client
end

run Sinatra::Application
