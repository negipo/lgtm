#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require
require 'uri'

module Lgtm
  module Requestable
    USER_AGENT = "lgtm web app - http://lgtm.herokuapp.com/ - mailto: #{ENV['MAIL_ADDRESS']}"

    def robots
      @robots ||= Robots.new(USER_AGENT)
    end

    def fetch(raw_uri)
      raise NotUrlException unless URI.regexp === raw_uri
      raise NotAllowedUrlException unless robots.allowed?(raw_uri)
      RestClient.get(raw_uri)
    end

    def raw_uri_by_path_info
      uri = request.path_info.sub(/\A\//, '')
      uri.sub(/\A(https?):\//) do
        "#{$1}://"
      end
    end

    class NotUrlException < Exception; end
    class NotAllowedUrlException < Exception; end
  end

  class App < Sinatra::Application
    CACHE_MAX_AGE = 10 * 24 * 60 * 60 # 10 days

    include Requestable
    class NotLgtmableImageException < Exception; end

    error RestClient::ResourceNotFound do
      status 404
      'image not found'
    end

    error RestClient::Forbidden do
      status 403
      'image forbidden'
    end

    error NotUrlException do
      status 403
      'not url'
    end

    error NotAllowedUrlException do
      status 403
      'image not accessable'
    end

    error NotLgtmableImageException do
      status 400
      return 'only animated gif supported'
    end

    get '/' do
      @domain = [
        request.host,
        [80, 8000].include?(request.port) ? nil : request.port
      ].join(':')
      haml :index
    end

    get '/*' do
      cache_control :public, max_age: CACHE_MAX_AGE

      response = fetch(raw_uri_by_path_info)

      unless /gif/ === response.headers[:content_type]
        raise NotLgtmableImageException
      end

      content_type response.headers[:content_type]
      Lgtm::ImageBuilder.new(response.body).build
    end
  end

  class ImageBuilder
    LGTM_IMAGE_WIDTH = 1_000

    def initialize(blob)
      @sources = ::Magick::ImageList.new.from_blob(blob).coalesce
    end

    def build
      images = ::Magick::ImageList.new

      @sources.each_with_index do |source, index|
        images << lgtmify(source)
      end

      images.delay = @sources.delay
      images.iterations = 0

      images.
        optimize_layers(Magick::OptimizeLayer).
        to_blob
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
      source.composite!(
        lgtm_image,
        ::Magick::CenterGravity,
        ::Magick::OverCompositeOp
      )
    end
  end
end
