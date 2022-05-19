# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  class Livecheck < Command
    def process(_args, _options)
      return run_process if $stdout.tty?

      redirect_stdout($stderr) do
        run_process
      end
    end

    def run_process
      installed = Cask.installed_apps
      installed.each do |app|
        system "brew", "livecheck", app[:token]
      end
    end
  end
end
