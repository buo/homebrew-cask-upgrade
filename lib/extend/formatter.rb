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

  class Table
    attr_accessor :header, :rows

    def initialize
      @header = []
      @rows = []
    end

    def add_header_column(value, align = "left")
      @header << Formatter::TableColumn.new(value: value, align: align)
    end

    def add_row(row)
      @rows << row
    end

    def output(gutter = 2)
      output = ""

      # Maximum number of columns
      cols = @header.length

      rows = [@header] + @rows

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

  def print_app_table(apps, state_info, options)
    table = self::Table.new
    table.add_header_column ""
    table.add_header_column "Cask"
    table.add_header_column "Current"
    table.add_header_column "Latest"
    table.add_header_column "A/U"
    table.add_header_column "Result", "center"
    table.add_header_column "URL" if options.verbose

    apps.each_with_index do |app, i|
      color, result = formatting_for_app(state_info, app, options).values_at(0, 1)

      row = []
      row << self::TableColumn.new(:value => "#{(i+1).to_s.rjust(apps.length.to_s.length)}/#{apps.length}")
      row << self::TableColumn.new(:value => app[:token], :color => color)
      row << self::TableColumn.new(:value => app[:current].join(","))
      row << self::TableColumn.new(:value => app[:version], :color => "magenta")
      row << self::TableColumn.new(:value => app[:auto_updates] ? " Y " : "", :color => "magenta")
      row << self::TableColumn.new(:value => result, :color => color)
      row << self::TableColumn.new(:value => app[:homepage], :color => "blue") if options.verbose

      table.add_row row
    end

    puts table.output
  end

  def formatting_for_app(state_info, app, options)
    if state_info[app] == "pinned"
      color = "cyan"
      result = "[ PINNED ]"
    elsif state_info[app][0, 6] == "forced"
      color = "yellow"
      result = "[ FORCED ]"
    elsif app[:auto_updates]
      if options.all
        color = "green"
        result = "[   OK   ]"
      else
        color = "default"
        result = "[  PASS  ]"
      end
    elsif state_info[app] == "outdated"
      color = "red"
      result = "[OUTDATED]"
    else
      color = "green"
      result = "[   OK   ]"
    end

    [color, result]
  end
end
