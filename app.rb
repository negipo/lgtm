#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require
require 'uri'

module Lgtm
  module Requestable
    USER_AGENT = "lgtm web app - http://lgtm.herokuapp.com/ - mailto: #{ENV['MAIL_ADDRESS']}"
    MAX_CONTENT_LENGTH = (ENV['MAX_CONTENT_LENGTH'] || 2_097_152).to_i

    def morito_client
      @morito_client ||= Morito::Client.new(USER_AGENT)
    end

    def fetch(raw_uri)
      raise NotUrlException unless URI.regexp === raw_uri
      raise NotAllowedUrlException unless morito_client.allowed?(raw_uri)
      content_length = RestClient.head(raw_uri, user_aget: USER_AGENT).headers[:content_length]
      raise OverMaxContentLengthException if content_length.to_i > MAX_CONTENT_LENGTH
      RestClient.get(raw_uri, user_agent: USER_AGENT)
    end

    def raw_uri_by_path_info
      uri = request.path_info.sub(/\A\/(?:(?:glitch|with_comments)\/)?/, '')
      uri.sub(/\A(https?):\//) do
        "#{$1}://"
      end
    end

    class NotUrlException < Exception; end
    class NotAllowedUrlException < Exception; end
    class OverMaxContentLengthException < Exception; end
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
      'only animated gif supported'
    end

    error OverMaxContentLengthException do
      status 403
      'over max content_length'
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
      Lgtm::ImageBuilder.new(
        response.body,
        glitch: glitch?,
        with_comments: with_comments?
      ).build
    end

    def glitch?
      /\A\/glitch\// === request.path_info
    end

    def with_comments?
      /\A\/with_comments\// === request.path_info
    end
  end

  class ImageBuilder
    LGTM_IMAGE_WIDTH = 1_000

    def initialize(blob, options = {})
      @sources = ::Magick::ImageList.new.from_blob(blob).coalesce
      @options = options.reverse_merge(glitch: false, with_comments: false)
    end

    def build
      images = ::Magick::ImageList.new

      @sources.each_with_index do |source, index|
        target = lgtmify(source)
        target = glitch(target) if @options[:glitch]
        target.delay = source.delay
        images << target
      end

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
      if @options[:with_comments]
        path = './images/lgtm_with_comments.gif'
      else
        path = './images/lgtm.gif'
      end
      @lgtm_image = ::Magick::ImageList.new(path).scale(scale)
    end

    def glitch(source)
      colors = []
      color_size = source.colors
      blob = source.to_blob
      color_size.times do |index|
        colors << blob[20 + index, 3]
      end
      color_size.times do |index|
        blob[20 + index, 3] = colors.sample
      end
      Magick::Image.from_blob(blob).first
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
