require "forwardable"

module Imap; end

module Imap::Backup
  module Text; end

  # Wraps standard output and hides passwords from debug output
  # Any text matching Net::IMAP debug output of passwords is sanitized
  class Text::Sanitizer
    extend Forwardable

    delegate puts: :output
    delegate write: :output

    # @param output [IO] the stream to write output to
    def initialize(output)
      @output = output
      @current = ""
    end

    # Outputs everything up to the last newline character,
    # storing whatever follows the newline.
    # @param args [Array<String>] lines of text
    # @return [void]
    def print(*args)
      @current << args.join
      loop do
        line, newline, rest = @current.partition("\n")
        break if newline != "\n"

        clean = sanitize(line)
        output.puts clean
        @current = rest
      end
    end

    # Outputs any text still not printed
    # @return [void]
    def flush
      return if @current == ""

      clean = sanitize(@current)
      output.puts clean
    end

    private

    attr_reader :output

    def sanitize(text)
      # Hide password in Net::IMAP debug output
      text.gsub(
        /\A(C: RUBY\d+ LOGIN \S+) \S+/,
        "\\1 [PASSWORD REDACTED]"
      )
    end
  end
end
