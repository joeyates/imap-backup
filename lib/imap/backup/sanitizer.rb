require "forwardable"

module Imap::Backup
  class Sanitizer
    extend Forwardable

    attr_reader :output

    delegate puts: :output
    delegate write: :output

    def initialize(output)
      @output = output
      @current = ""
    end

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

    def flush
      return if @current == ""

      clean = sanitize(@current)
      output.puts clean
    end

    private

    def sanitize(t)
      # Hide password in Net::IMAP debug output
      t.gsub(
        /\A(C: RUBY\d+ LOGIN \S+) \S+/,
        "\\1 [PASSWORD REDACTED]"
      )
    end
  end
end
