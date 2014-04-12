require 'rack'
require './app'
require './lib/cache_configuration'

if CacheConfiguration.available?
  use Rack::Cache, CacheConfiguration.options
end

run Lgtm::App
