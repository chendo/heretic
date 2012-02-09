$LOAD_PATH << File.dirname(__FILE__)

require "rubygems"
require "json"
require "heretic/version"
require "heretic/local_object_proxy"

class Heretic
  def self.start
    new.run
  end

  def initialize
    @registry = {}
  end

  def log(*args)
    $stderr.puts(args.join("\n")) if true
    args
  end

  def run
    while !$stdin.eof?
      IO.select([$stdin], [], [])

      data = $stdin.gets
      next if data.nil?

      Thread.start do
        parse_and_handle(data)
      end

    end
  end

  def parse_and_handle(data)
    return if data.length.zero?
    json = JSON.parse(data)

    log "Received: #{json.inspect}"
    case json['op']
    when 'eval'
      send_object proxify_and_store(eval(json['code']), :by_reference => !!json['by_reference'])
    when 'call'
      ret = @registry[json['object_proxy_id']].call(json['method_name'], json['args'])
      log("Return: #{ret.inspect}")
      send_object proxify_and_store(ret)
    else
      $stderr.puts "Unrecognised operation"
    end
  rescue => e
    log("Exception: #{e.inspect}")
  end

  def send_object(object)
    # Send the object back
    message = {
      'op' => 'return',
      'value' => object
    }
    send message
  end

  def send(message)
    write_to_pipe JSON.generate(message)
  end

  def write_to_pipe(data)
    log("Sending: #{data}")
    $stdout.puts data
    $stdout.flush
  end

  def proxify_and_store(object, options = {})

    proxify(object, options)

  end

  def proxify(object, options = {})
    # If by_reference requested, proxy the object regardless
    # If object doesn't respond to to_json, proxy the object
    # If array, map proxify over the elements
    # If hash, map over each element
    # Otherwise to_json
    log("Proxifying: #{object.inspect}")
    if [String, Integer, Float, String, TrueClass, FalseClass].any? { |klass| object.is_a?(klass) }
      object
    elsif options[:by_reference]
      return find_or_create_proxy(object, options)
    elsif object.is_a?(Array)
      # TODO: Bench map vs map!
      object.map! { |e| proxify(e, options) }
    elsif object.is_a?(Hash)
      # TODO: Bench inline array create or another recursive call
      hash = {}
      object.each do |key, value|
        hash[proxify(key, options)] = proxify(value, options)
      end
      hash
    else
      return find_or_create_proxy(object, options)
    end

  end

  def find_or_create_proxy(object, options = {})
    if @registry[key_for_object(object)] # TODO: Refactor
      @registry[key_for_object(object)]
    else
      LocalObjectProxy.new(object).tap do |proxy|
        store_proxy(proxy)
      end
    end
  end

  def key_for_object(object)
    object.object_id
  end

  def store_proxy(proxy)
    @registry[proxy.key] = proxy
  end
end
