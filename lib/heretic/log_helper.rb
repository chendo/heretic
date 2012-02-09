class Heretic
  module LogHelper
    def log(*args)
      $stderr.puts("PID: #{Process.pid} - #{args.join("\n")}") if true
      args
    end
  end
end
