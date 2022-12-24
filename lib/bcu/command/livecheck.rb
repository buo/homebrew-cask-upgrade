# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  class Livecheck < Command
    def process(_args, options)
      return run_process(options) if $stdout.tty?

      redirect_stdout($stderr) do
        run_process(options)
      end
    end

    def run_process(options)
      installed = Cask.installed_apps(options)
      installed.each do |app|
        system "brew", "livecheck", app[:token]
      end
    end
  end
end
