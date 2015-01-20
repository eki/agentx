
require 'agentx/version'

require 'digest/md5'
require 'time'
require 'uri'

require 'ethon'
require 'http-cookie'
require 'nokogiri'
require 'oj'
require 'sqlite3'

require 'agentx/history'
#require 'agentx/cookie_jar'
require 'agentx/html'
require 'agentx/xml'
require 'agentx/request'
require 'agentx/response'
require 'agentx/cache'
require 'agentx/session'

module AgentX
  def self.root
    return @root if @root

    @root = File.expand_path('~/.agentx')

    Dir.mkdir(@root) unless Dir.exists?(@root)

    @root
  end

  def self.session
    @session ||= Session.new
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

