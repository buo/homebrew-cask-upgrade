module Formatter
  module_function

  def table(rows, gutter: 2)
    output = ""

    # Maximum number of columns
    cols = rows.map(&:length).max

    # Calculate column widths
    col_widths = Array.new(cols, 0)
    rows.each do |row|
      row.each_with_index do |obj, i|
        len = Tty.strip_ansi(obj.to_s).length
        col_widths[i] = len if col_widths[i] < len
      end
    end

    # Calculate table width including gutters
    table_width = col_widths.inject(:+) + gutter * (cols - 1)

    # Print table header
    output << "=" * table_width + "\n"
    rows.shift.each_with_index do |obj, i|
      output << obj.to_s.ljust(col_widths[i] + gutter)
    end
    output << "\n"
    output << "=" * table_width + "\n"

    # Print table body
    rows.each do |row|
      row.each_with_index do |obj, i|
        padding = col_widths[i] - Tty.strip_ansi(obj.to_s).length + gutter
        output << "#{obj}#{" " * padding}"
      end
      output << "\n"
    end
    output << "=" * table_width + "\n"

    output
  end
end
