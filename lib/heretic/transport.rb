class Heretic
  class Transport
    include LogHelper

    attr_accessor :processor

    def initialize(input_io = $stdin, output_io = $stdout)
      @input = input_io
      @output = output_io
    end

    def run
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

    def send_object(object)
      # Send the object back
      message = {
        'op' => 'return',
        'object' => object
      }
      send message
    end

    def send(message)
      write_to_pipe JSON.generate(message)
    end

    def write_to_pipe(data)
      log("Sending: #{data}")
      output.puts data
      output.flush
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
