
require 'agentx/version'

require 'digest/md5'
require 'time'
require 'uri'

require 'ethon'
require 'http-cookie'
require 'nokogiri'
require 'oj'
require 'sqlite3'

require 'agentx/html'
require 'agentx/xml'

require 'agentx/http/history'
require 'agentx/http/request'
require 'agentx/http/response'
require 'agentx/http/cache'
require 'agentx/http/session'

module AgentX
  def self.root
    return @root if @root

    @root = File.expand_path('~/.agentx')

    Dir.mkdir(@root) unless Dir.exists?(@root)

    @root
  end

  def self.session
    @session ||= Http::Session.new
  end

  def self.[](*args)
    session[*args]
  end

  def self.logger
    return @logger if @logger

    @logger = Logger.new(File.join(root, 'request.log'))

    @logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime} | #{msg}\n"
    end

    @logger
  end
end

