module ZQ
  extend self

  def comment?(string)
    string =~ /^[[:space:]]*(#.*)?$/
  end

  def indented?(string)
    string =~ /^[[:space:]]/
  end

  def value?(string)
    string =~ /[^'"]=[^"']/
  end

  def unindent(string)
    string.sub /^(    |\t)/, ""
  end

  def unquote(string)
    string =~ /^['"].*["']$/ ? string.sub(/^['"]/, "").sub(/["']$/, "") : string
  end

  def uncomment(string)
    trim_trailing_whitespace string.sub(/#[^'"]*$/, "")
  end

  def trim_leading_spaces(string)
    string.sub /^ +/, ""
  end

  def trim_leading_whitespace(string)
    string.sub /^[[:space:]]+/, ""
  end

  def trim_trailing_whitespace(string)
    string.sub /[[:space:]]*$/, ""
  end

  def trim_surrounding_whitespace(string)
    trim_leading_whitespace trim_trailing_whitespace string
  end

  def normalize_indentation(string)
    step = string.sub /^(\t)*    /, "\\1\t"
    step == string ? trim_leading_spaces(step) : normalize_indentation(step)
  end

  def indentation(string)
    string.sub /(\t*).*/, "\\1"
  end

  def key(string)
    unquote trim_surrounding_whitespace string.split("=").first
  end

  def value(string)
    unquote trim_surrounding_whitespace string
                                          .split("=")
                                          .tap { |l| l.shift }
                                          .join("=")
  end

  def format(string)
    property = [key(string), value(string)].reject(&.blank?).join(" = ")
    indentation(string) + property
  end

  def read(io)
    stream = [] of String
    io.each_line { |line| stream << uncomment(line.chomp) unless comment? line }
    stream
      .map { |line| format normalize_indentation line }
  end

  def walk(keys, lines)
    key = keys.shift
    captured = [] of String
    capturing = false

    lines.each do |line|
      case line
      when .starts_with? key
        value?(line) ? (captured << value(line)) : (capturing = true)
      when /^[[:space:]]/
        captured << unindent(line) if capturing
      else
        capturing = false
      end
    end

    keys.empty? ? captured : walk(keys, captured)
  end
end

puts (ARGV.empty? ? ZQ.read(STDIN) : ZQ.walk(ARGV, ZQ.read(STDIN))).join("\n")
