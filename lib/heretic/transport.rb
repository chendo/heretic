class Heretic
  class Transport
    include LogHelper

    attr_accessor :processor, :input, :output

    def initialize(input_io = $stdin, output_io = $stdout)
      @input = input_io
      @output = output_io
      @message_id = 0
      @callbacks = {}
      @mutex = Mutex.new
    end

    def listen
      while !input.eof?
        IO.select([input])

        data = input.gets

        next if data.nil?

        process(data)
      end
    end

    def process(data)
      Thread.start do
        message = JSON.parse(data)
        @processor.process(message)
      end
    end

    def call(object_proxy_id, method, args = [])
      message = {
        'op' => 'call',
        'object_proxy_id' => object_proxy_id,
        'method_name' => method,
        'args' => args
      }
      send message
    end

    def send_object(object, message_id)
      # Send the object back
      message = {
        'op' => 'return',
        'object' => object,
        'id' => message_id
      }
      send message, :async => true
    end

    def send(message, options = {})
      @message_id += 1
      message.merge!('id' => @message_id) unless message['id']
      if !options[:async]
        r, w = IO.pipe
        @processor.add_callback(@message_id, w, Thread.current)
        write_to_pipe JSON.generate(message)
        r.eof? # Block until other end is closed
        Thread.current[:__heretic_return_value]
      else
        write_to_pipe JSON.generate(message)
      end
    end

    def write_to_pipe(data)
      log("Sending: #{data}")
      IO.select([], [output])

      @mutex.synchronize do
        output.puts data
        output.flush
      end
    end

    private

    def input
      @input
    end

    def output
      @output
    end
  end
end
