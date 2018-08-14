require "mail"

module Email; end

module Email::Mboxrd
  class Message
    attr_reader :supplied_body

    def initialize(supplied_body)
      @supplied_body = supplied_body.clone
      @supplied_body.force_encoding("binary")
    end

    def to_s
      "From " + from + "\n" + mboxrd_body + "\n"
    end

    private

    def parsed
      @parsed ||= Mail.new(supplied_body)
    end

    def best_from
      if parsed.from.is_a?(Enumerable)
        parsed.from.each do |addr|
          return addr if addr
        end
      end

      return parsed.sender if parsed.sender
      return parsed.envelope_from if parsed.envelope_from
      return parsed.return_path if parsed.return_path

      return ""
    end

    def from
      best_from + " " + asctime
    end

    def mboxrd_body
      return @mboxrd_body if @mboxrd_body
      @mboxrd_body = supplied_body.gsub(/\n(>*From)/, "\n>\\1")
      @mboxrd_body += "\n" unless @mboxrd_body.end_with?("\n")
      @mboxrd_body
    end

    def asctime
      date ? date.asctime : ""
    end

    def date
      parsed.date
    end
  end
end
