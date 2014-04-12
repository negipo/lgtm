#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require
require 'net/http'
require 'uri'

module Lgtm
  module Requestable
    def fetch(raw_uri, limit=10)
      raise ArgumentError if limit < limit

      uri = URI.parse(raw_uri)
      request = Net::HTTP::Get.new(uri.path)
      response = Net::HTTP.start(uri.host, uri.port) {|http|
        http.request(request)
      }

      case response
      when Net::HTTPSuccess
        response
      when Net::HTTPRedirection, Net::HTTPFound
        fetch(response['location'], limit - 1)
      else
        raise Exception.new('network error')
      end
    end

    def raw_uri_by_path_info
      uri = request.path_info.sub(/\A\//, '')
      uri.sub(/\A(http):\//) do
        "#{$1}://"
      end
    end
  end

  class App < Sinatra::Application
    CACHE_MAX_AGE = 10 * 24 * 60 * 60 # 10 days

    include Requestable

    get '/' do
      @domain = [
        request.host,
        [80, 8000].include?(request.port) ? nil : request.port
      ].join(':')
      haml :index
    end

    get '/favicon.ico' do
    end

    get '/*' do
      cache_control :public, max_age: CACHE_MAX_AGE

      response = fetch(raw_uri_by_path_info)
      unless /gif/ === response.content_type
        return 'only animated gif supported'
      end

      content_type response.content_type
      Lgtm::ImageBuilder.new(response.body).build
    end
  end

  class ImageBuilder
    LGTM_IMAGE_WIDTH = 1_000

    def initialize(blob)
      @sources = ::Magick::ImageList.new.from_blob(blob)
    end

    def build
      images = ::Magick::ImageList.new

      @sources.each do |source|
        images << lgtmify(source)
      end

      images.delay = @sources.delay
      images.iterations = 0

      images.to_blob
    end

    private

    def width
      @sources.first.columns
    end

    def height
      @sources.first.rows
    end

    def lgtm_image
      return @lgtm_image if @lgtm_image

      scale = width.to_f / LGTM_IMAGE_WIDTH
      @lgtm_image = ::Magick::ImageList.new('./images/lgtm.gif').scale(scale)
    end

    def lgtmify(source)
      # Prevent centerize corruptions.
      source.resize!(width, height)

      source.composite!(
        lgtm_image,
        ::Magick::CenterGravity,
        ::Magick::OverCompositeOp
      )
    end
  end
end
