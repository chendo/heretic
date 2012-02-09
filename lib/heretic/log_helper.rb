class Heretic
  module LogHelper
    def log(*args)
      $stderr.puts(args.join("\n")) if true
      args
    end
  end
end
