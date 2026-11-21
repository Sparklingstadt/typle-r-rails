require "csv"

# One row of a word list as text: tab-separated when the line has a tab, CSV otherwise.
module WordRow
  module_function

  def parse(line)
    cells = line.include?("\t") ? line.split("\t", -1) : (CSV.parse_line(line, strip: true) || [])
    cells.map { |cell| cell.to_s.strip }.values_at(0, 1, 2)
  rescue CSV::MalformedCSVError
    [line.strip, nil, nil]
  end
end
