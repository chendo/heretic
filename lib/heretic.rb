$LOAD_PATH << File.dirname(__FILE__)

require "rubygems"
require "json"
require "heretic/version"
require "heretic/log_helper"
require "heretic/local_object_proxy"
require "heretic/remote_object_proxy"
require "heretic/processor"
require "heretic/transport"
require "heretic/registry"
require "pty"

class Heretic
  def self.listen
    new.listen
  end

  def self.spawn(command)
    new.tap do |heretic|
      heretic.connect(command)
    end
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

  def listen
    @transport.listen
  end

  def connect(command, *args)
    stdout_read_end, stdout_write_end = IO.pipe
    stdin_read_end, stdin_write_end = IO.pipe
    stderr = $stderr
    @pid = fork do
      STDIN.reopen(stdin_read_end)
      STDOUT.reopen(stdout_write_end)
      # STDERR.reopen(stder)
      exec(command, *(args.map { |a| a.to_s }))
    end

    @transport.input = stdout_read_end
    @transport.output = stdin_write_end

    # stdout, stdin, @pid = PTY.spawn(command, *args)

    # @transport.output = stdin
    # @transport.input = stdout

    log "Connected"

    trap_signals

    Thread.start do
      @transport.listen
    end
  end

  def trap_signals
    Signal.trap(0, proc { stop })
    Signal.trap(3, proc { stop })
    Signal.trap(9, proc { stop })
  end

  def stop
    if @pid
      log "Stopping #{@pid}"
      Process.kill("TERM", @pid)
      Process.waitpid(@pid)
    end
  end

  def eval(code, &block)
    @transport.send({
      'op' => 'eval',
      'code' => code
    }, &block)
  end


end
