class Heretic
  class Registry
    include LogHelper

    def initialize
      @object_proxies = {}
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

    def [](object_proxy_id)
      @object_proxies[object_proxy_id]
    end

    def find_or_create_proxy(object, options = {})
      if @object_proxies[key_for_object(object)] # TODO: Refactor
        @object_proxies[key_for_object(object)]
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
      @object_proxies[proxy.key] = proxy
    end
  end
end
