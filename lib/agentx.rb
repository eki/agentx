
require 'agentx/version'

require 'digest/md5'
require 'time'
require 'uri'

require 'ethon'
require 'http-cookie'
require 'nokogiri'
require 'oj'

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
end

