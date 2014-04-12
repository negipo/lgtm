class CacheConfiguration
  class << self
    def options
      {
        metastore: client,
        entitystore: client
      }
    end

    def available?
      !servers.nil?
    end

    def client
      @client ||= Dalli::Client.new(
        servers,
        auth_options.merge(value_max_bytes: 10485760)
      )
    end

    private

    def auth_options
      if ENV["MEMCACHEDCLOUD_USERNAME"]
        {
          username: ENV["MEMCACHEDCLOUD_USERNAME"],
          password: ENV["MEMCACHEDCLOUD_PASSWORD"]
        }
      else
        {}
      end
    end

    def servers
      if ENV["MEMCACHE_SERVERS"]
        ENV["MEMCACHE_SERVERS"].split(',')
      elsif ENV["MEMCACHEDCLOUD_SERVERS"]
        ENV["MEMCACHEDCLOUD_SERVERS"].split(',')
      end
    end
  end
end
