require File.dirname(__FILE__) + "/../lib/heretic"

heretic = Heretic.spawn("ruby heretic_listener.rb")


require 'benchmark'

10.times do |i|
  Thread.start do
    Benchmark.bm do |x|
      x.report do
        1000.times do
          puts i
          heretic.eval("1")
        end
        puts "done: #{i}"
      end
    end
  end
end
# p "Time: #{heretic.eval("Time.now").to_s}"

heretic.join
