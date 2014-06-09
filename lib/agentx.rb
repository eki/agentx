
require 'agentx/version'

require 'time'
require 'uri'

require 'ethon'
require 'http-cookie'
require 'nokogiri'
require 'oj'

require 'agentx/history'
#require 'agentx/cookie_jar'
require 'agentx/html'
require 'agentx/request'
require 'agentx/response'
require 'agentx/session'

module AgentX
  def self.session
    @session ||= Session.new
  end

  def self.[](*args)
    session[*args]
  end
end

