module Bcu
  class Command
    class CommandNotImplementedError < NoMethodError
    end

    def process(_args, _options)
      raise Command::CommandNotImplementedError, "#{self.class.name} needs to implement 'process' method!"
    end
  end
end
