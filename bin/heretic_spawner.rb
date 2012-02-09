require File.dirname(__FILE__) + "/../lib/heretic"

heretic = Heretic.spawn("ruby heretic_listener.rb")

heretic.eval("Time.now") do |time|
  puts time.to_i
end

sleep 10
