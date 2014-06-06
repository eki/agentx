
require 'agentx/version'

require 'time'

require 'ethon'
require 'nokogiri'
require 'oj'

require 'agentx/history'
require 'agentx/cookie_jar'
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
