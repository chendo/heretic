class Heretic
  class Processor
    include LogHelper

    attr_accessor :registry, :transport

    def initialize
      @message_id = 1
      @callbacks = {}
    end

    def process(message)

      log "Received: #{message.inspect}"
      case message['op']
      when 'eval'
        handle_eval(message)
      when 'call'
        handle_call(message)
      when 'return'
        handle_return(message)
      else
        $stderr.puts "Unrecognised operation"
      end
    rescue => e
      log("Exception: #{e.inspect}")
      log(e.backtrace.join("\n"))
    end

    def add_callback(message_id, &block)
      return unless block_given?
      log "Adding callback for id #{message_id}: #{block.inspect}"
      @callbacks[message_id] = block
    end

    def handle_eval(message)
      object = eval(message['code'])
      proxy = proxify_and_store(object, :by_reference => !!message['by_reference'])
      send_object proxy, message['id']
    end

    def handle_call(message)
      proxy = get_object_proxy(message['object_proxy_id'])
      ret = proxy.call(message['method_name'], message['args'])
      log("Return: #{ret.inspect}")
      send_object proxify_and_store(ret), message['id']
    end

    def handle_return(message)
      log "Handling return: #{message.inspect}"
      ret = message['object']
      if ret.is_a?(Hash) && object_proxy_id = ret['__object_proxy_id']
        proxy = RemoteObjectProxy.new(object_proxy_id, @transport)
        log "Creating proxy: #{proxy}"
        log @callbacks.inspect
        if block = @callbacks[message['id']]
          log "Callback found: #{block}"
          block.call(proxy)
        end
      end
    end

    def proxify_and_store(object, options = {})
      registry.proxify_and_store(object, options)
    end

    def get_object_proxy(object_proxy_id)
      registry[object_proxy_id]
    end

    def send_object(object, message_id)
      transport.send_object(object, message_id)
    end

  end
end
