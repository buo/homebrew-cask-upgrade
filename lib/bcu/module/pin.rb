module Bcu
  module Pin
    PINS_FILE = File.expand_path(File.dirname(__FILE__) + "/../../../pinned")

    def pinned
      @pinned ||= begin
        FileUtils.touch PINS_FILE

        pinned = Set[]
        File.open(PINS_FILE, "r") do |f|
          f.each_line do |cask|
            pinned.add(cask.rstrip)
          end
        end

        pinned
      end
    end

    module_function :pinned
  end
end
