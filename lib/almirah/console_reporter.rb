# frozen_string_literal: true

# Reporter prints concise, aligned progress lines for the processing pipeline:
#
#   parsing specifications ..... 4 ok
#   parsing test protocols ..... 2 ok
#   parsing decisions .......... 14 ok
#   traceability matrices ...... 4 ok
#   coverage matrices .......... 1 ok
#   implementation matrices .... 1 ok
#   decision links ............. 5 ok
#   rendering HTML ............. ./build/index.html
#
# ANSI colour is applied only when writing to an interactive terminal, so piped
# or captured output stays clean.
module ConsoleReporter
  COLUMN = 28 # label is dot-padded out to this column, then the value follows

  module_function

  def count(label, number)
    emit(label, "#{number} ok", 92) # green highlight
  end

  def result(label, value)
    emit(label, value, 96) # cyan highlight
  end

  def emit(label, value, color_code)
    dotted = "#{label} ".ljust(COLUMN, '.')
    puts "#{dotted} #{colorize(value, color_code)}"
  end

  def colorize(text, color_code)
    $stdout.tty? ? "\e[#{color_code}m#{text}\e[0m" : text
  end
end
