class Heretic
  module LogHelper
    def log(*args)
      $stderr.puts("PID: #{Process.pid} - #{args.join("\n")}") if false
      args
    end
  end
end
