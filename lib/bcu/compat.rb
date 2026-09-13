# frozen_string_literal: true

module Bcu
  # Shims for Homebrew APIs that moved or were removed between releases, so
  # the tap keeps working on both sides of each change.
  module Compat
    module_function

    # Homebrew 7.0.0 removed the global `redirect_stdout` (Homebrew/brew
    # commit 15069d12a0) in favour of `Utils::Output.redirect_stdout`, a
    # module function that is deliberately not part of
    # `Utils::Output::Mixin` - so including the mixin does not bring it back.
    # Delegate to it when present and fall back to the removed body otherwise.
    def redirect_stdout(file, &block)
      if defined?(Utils::Output) && Utils::Output.respond_to?(:redirect_stdout)
        Utils::Output.redirect_stdout(file, &block)
      else
        legacy_redirect_stdout(file, &block)
      end
    end

    # The pre-7.0.0 global, verbatim.
    def legacy_redirect_stdout(file)
      out = $stdout.dup
      $stdout.reopen(file)
      yield
    ensure
      $stdout.reopen(out)
      out.close
    end
  end
end
