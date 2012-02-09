$LOAD_PATH << File.dirname(__FILE__)

require "rubygems"
require "json"
require "heretic/version"
require "heretic/log_helper"
require "heretic/local_object_proxy"
require "heretic/processor"
require "heretic/transport"
require "heretic/registry"

class Heretic
  def self.start
    new.run
  end

  include LogHelper

  def initialize
    @registry = {}
    @transport = Transport.new
    @processor = Processor.new
    @registry = Registry.new

    @processor.registry = @registry
    @transport.processor = @processor
    @processor.transport = @transport
  end

  def run
    @transport.run
  end

end
