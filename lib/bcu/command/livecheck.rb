# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  class Livecheck < Command
    def process(args, options)
      return run_process(args) if $stdout.tty?

      redirect_stdout($stderr) do
        run_process(args)
      end
    end

    def run_process(_args)
      installed = Cask.installed_apps
      installed.each do |app|
        system "brew", "livecheck", app[:token]
      end
    end
  end
end
