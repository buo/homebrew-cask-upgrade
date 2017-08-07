module Formatter
  module_function

  class TableColumn
    attr_accessor :align, :color, :value, :width
    def initialize(args)
      @align = args[:align].nil? ? "left" : args[:align]
      @color = args[:color].nil? ? "default" : args[:color]
      @value = args[:value].nil? ? "" : args[:value].to_s
      @width = args[:width].nil? ? 0 : args[:width]
    end
  end

  def colorize(string, color)
    "#{Tty.send(color)}#{string}#{Tty.reset}"
  end

  def state(string, color: "default")
    "[#{Tty.send(color)}#{string}#{Tty.reset}]"
  end

  def truncate(string, len: 10, suffix: "...")
    return string if string.length <= len
    "#{string[0, len - suffix.length]}#{suffix}"
  end

  def table(rows, gutter: 2)
    output = ""

    # Maximum number of columns
    cols = rows.map(&:length).max

    # Calculate column widths
    col_widths = Array.new(cols, 0)
    rows.each do |row|
      row.each_with_index do |col, i|
        len = col.value.length
        col_widths[i] = len if col_widths[i] < len
      end
    end

    # Calculate table width including gutters
    table_width = col_widths.inject(:+) + gutter * (cols - 1)

    if table_width > Tty.width
      content_width = Tty.width - gutter * (cols - 1) - gutter
      overflow_cols = 0
      max_width = content_width
      col_widths.each do |width|
        if width <= content_width / cols
          max_width -= width
        else
          overflow_cols += 1
        end
      end
      max_width /= overflow_cols

      # Re-calculate column widths
      col_widths = Array.new(cols, 0)
      rows.each do |row|
        row.each_with_index do |col, i|
          len = [col.value.length, max_width].min
          col_widths[i] = len if col_widths[i] < len
        end
      end

      # Truncate values
      rows = rows.map do |row|
        row.map.with_index do |col, i|
          col.value = Formatter.truncate(col.value, len: col_widths[i])
          col
        end
      end
    end

    # Print table header
    rows.shift.each_with_index do |th, i|
      string = "#{Tty.underline}#{th.value}#{Tty.reset}"
      padding = col_widths[i] - th.value.length
      if th.align == "center"
        padding_left = padding / 2
        padding_right = padding - padding_left
        padding_right += gutter unless i - 1 == cols
        output << "#{" " * padding_left}#{string}#{" " * padding_right}"
      else
        padding += gutter unless i - 1 == cols
        output << "#{string}#{" " * padding}"
      end
    end
    output << "\n"

    # Print table body
    rows.each do |row|
      row.each_with_index do |td, i|
        padding = col_widths[i] - td.value.length
        padding += gutter unless i - 1 == cols
        output << "#{Tty.send(td.color)}#{td.value}#{Tty.reset}#{" " * padding}"
      end
      output << "\n"
    end

    output
  end
end
