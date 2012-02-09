class Heretic
  class LocalObjectProxy
    attr_reader :created_at, :object, :options

    def initialize(object, options = {})
      @object = object
      @created_at = Time.now
      # Check if still needed
      @options = options
    end

    def key
      @key ||= object.object_id
    end

    def ==(other)
      object == other.object
    end

    def to_json(*args)
      {
        :__object_proxy_id => key,
      }.to_json(*args)
    end

    def call(method_name, args = [])
      object.send(method_name, *args)
    end
  end
end
