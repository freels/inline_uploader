require 'digest/md5'
require 'fileutils'
require 'tmpdir'
require 'logger'
require 'yaml'

class InlineUploader

  # 32 is the length of an md5 hex digest
  TAG_PREFIX = 'inline_upload_'.freeze
  TAG_REGEXP = /\A#{TAG_PREFIX}[a-z0-9]{32,32}\Z/i.freeze
  TAG_LENGTH = TAG_PREFIX.length + 32

  DEFAULT_ENDPOINT    = '/inline_upload'
  DEFAULT_UPLOAD_FLAG = 'has_inline_uploads'

  def self.new(inner_app, options = {})
    uploader = allocate
    uploader.send :initialize, options

    Rack::Builder.app do
      map uploader.endpoint do
        run InlineUploader::EndPoint.new(uploader)
      end

      map '/' do
        use InlineUploader::Attacher, uploader
        run inner_app
      end
    end
  end

  attr_reader :upload_dir, :endpoint, :flag_param, :logger

  def initialize(options)
    @upload_dir = options[:tmp_dir]     || File.join(Dir.tmpdir, "inline_uploader_#{Process.pid}#{Time.now.to_i}")
    @flag_param = options[:upload_flag] || DEFAULT_UPLOAD_FLAG
    @endpoint   = options[:endpoint]    || DEFAULT_ENDPOINT
    @logger     = options[:logger]      || Logger.new($stderr)

    FileUtils.mkdir_p(upload_dir)
  end

  class Attacher
    def initialize(app, delegate)
      @delegate = delegate
      @app      = app
    end

    def call(env)
      request = Rack::Request.new(env)

      # we have to look at both get and post as if Rack::Request.params 
      # has been called, GET will also contain all POST params. go figure.
      attach_previous_uploads request.GET, request.POST do
        return @app.call(env)
      end
    end

    def attach_previous_uploads(*hashes)
      return yield unless hashes.inject(false) {|others,h| !h.delete(@delegate.flag_param).nil? or others }

      logger.info "Attaching Inline Upload Tags."
      fds = {}

      begin
        hashes.each {|h| fds.merge! attach_fds(h) }

        yield

      ensure
        fds.values.each do |f|
          f.close unless f.closed?
          FileUtils.rm(f.path) if File.exist?(f.path)
        end
      end
    end

    def attach_fds(params)
      params.inject({}) do |fds, kv|
        key, val = kv

        # if node is a hash, proces each key to spot replaceable strings
        if val.is_a? Hash
          fds.merge! attach_fds(params[key])

        # if node is an rray, proces each element of the array recursively
        elsif val.is_a? Array
          params[key].each { |v| fds.merge! attach_fds(v) }

        # node is a string - could it be an inline upload?
        elsif tag = get_valid_tag(val)
          upload = File.join(@delegate.upload_dir, tag)

          if File.exist?(upload)
            file            = YAML.load_file("#{upload}_meta")
            file[:name]     = key
            file[:tempfile] = File.open(upload, 'rb')

            params[key] = file
            fds[tag]    = file[:tempfile]

            logger.info "attaching upload file at #{upload}"
          else
            params[key] = nil

            logger.info "no upload file found at #{upload}"
          end
        end

        fds
      end
    end

    # returns a valid tag or nil.
    def get_valid_tag(val)
      val if val.is_a? String and val.length == TAG_LENGTH and val =~ TAG_REGEXP
    end

    def logger
      @delegate.logger
    end
  end

  class EndPoint
    HEADERS     = {'Content-Type' => 'text/plain'}
    SUCCESS     = [200, HEADERS, ['success']]
    BAD_REQUEST = [400, HEADERS, ['bad request']]
    ERROR       = [500, HEADERS, ['error']]

    class BadRequestError < StandardError; end

    def initialize(delegate)
      @delegate = delegate
    end

    def call(env)
      request = Rack::Request.new(env)
      raise BadRequestError unless valid_request? request

      tag = request.params.keys.detect {|k| valid_tag? k }
      raise BadRequestError unless tag

      file = request.params[tag]
      raise BadRequestError unless file.member?(:tempfile)

      p request.params

      upload = File.join(@delegate.upload_dir, tag)

      FileUtils.mkdir_p @delegate.upload_dir
      FileUtils.move file[:tempfile].path, upload

      File.open("#{upload}_meta", 'w') do |f|
        file.delete(:tempfile)
        f.puts file.to_yaml
      end

      SUCCESS
    rescue BadRequestError
      BAD_REQUEST
    rescue Exception => e
      logger.error e.inspect
      logger.error e.backtrace.join("\n")
      ERROR
    end

    private

    def valid_request?(req)
      req.post? and req.content_type =~ %r|multipart/form-data|
    end

    def valid_tag?(tag)
      tag.is_a? String and tag.length == TAG_LENGTH and tag =~ TAG_REGEXP
    end

    def logger
      @delegate.logger
    end
  end

  module Helpers
    def inline_upload_tag(label = :default)
      @inline_upload_tags ||= {}
      @inline_upload_tags[label] ||= begin
        hsh = Digest::MD5.hexdigest("I like turtles! #{rand} #{Time.now.to_f}")
        "#{TAG_PREFIX}#{hsh}"
      end
    end
  end
end
