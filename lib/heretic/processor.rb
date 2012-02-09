class Heretic
  class Processor
    include LogHelper

    attr_accessor :registry, :transport

    def initialize

    end

    def process(message)

      log "Received: #{message.inspect}"
      case message['op']
      when 'eval'
        evaluate(message)
      when 'call'
        call(message)
      else
        $stderr.puts "Unrecognised operation"
      end
    rescue => e
      log("Exception: #{e.inspect}")
      log(e.backtrace.join("\n"))
    end

    def evaluate(message)
      object = eval(message['code'])
      proxy = proxify_and_store(object, :by_reference => !!message['by_reference'])
      send_object proxy
    end

    def call(message)
      proxy = get_object_proxy(message['object_proxy_id'])
      ret = proxy.call(message['method_name'], message['args'])
      log("Return: #{ret.inspect}")
      send_object proxify_and_store(ret)
    end

    def proxify_and_store(object, options = {})
      registry.proxify_and_store(object, options)
    end

    def get_object_proxy(object_proxy_id)
      registry[object_proxy_id]
    end

    def send_object(object)
      transport.send_object(object)
    end

  end
end
