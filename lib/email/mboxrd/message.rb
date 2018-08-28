require "mail"

module Email; end

module Email::Mboxrd
  class Message
    attr_reader :supplied_body

    def self.from_serialized(serialized)
      cleaned = serialized.gsub(/^>(>*From)/, "\\1")
      # Serialized messages in this format *should* start with a line
      #   From xxx yy zz
      if cleaned.start_with?("From ")
        cleaned = cleaned.sub(/^From .*[\r\n]*/, "")
      end
      new(cleaned)
    end

    def initialize(supplied_body)
      @supplied_body = supplied_body.clone
      @supplied_body.force_encoding("binary")
    end

    def to_serialized
      "From " + from + "\n" + mboxrd_body
    end

    def date
      parsed.date
    end

    def imap_body
      supplied_body.gsub(/(?<!\r)\n/, "\r\n")
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
      @from ||=
        begin
          from = best_from.dup
          from << " " + asctime if asctime != ""
          from
        end
    end

    def mboxrd_body
      @mboxrd_body ||=
        begin
          mboxrd_body = add_extra_quote(supplied_body.gsub("\r\n", "\n"))
          mboxrd_body += "\n" if !mboxrd_body.end_with?("\n")
          mboxrd_body += "\n" if !mboxrd_body.end_with?("\n\n")
          mboxrd_body
        end
    end

    def add_extra_quote(body)
      # The mboxrd format requires that lines starting with 'From'
      # be prefixed with a '>' so that any remaining lines which start with
      # 'From ' can be taken as the beginning of messages.
      # http://www.digitalpreservation.gov/formats/fdd/fdd000385.shtml
      # Here we add an extra '>' before any "From" or ">From".
      body.gsub(/\n(>*From)/, "\n>\\1")
    end

    def asctime
      @asctime ||= date ? date.asctime : ""
    end
  end
end
