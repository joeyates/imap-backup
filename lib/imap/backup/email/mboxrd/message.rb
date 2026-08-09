require "mail"

module Imap; end

module Imap::Backup
  module Email; end

  module Email::Mboxrd
    # Handles serialization and deserialization of messages
    class Message
      # @param serialized [String] an email message
      #
      # @return [String] The message without the initial 'From ' line
      #   and with one level of '>' quoting removed from other lines
      #   that start with 'From'
      def self.clean_serialized(serialized)
        cleaned = serialized.gsub(/^>(>*From )/, "\\1")
        # Serialized messages in this format *should* start with a line
        #   From xxx yy zz
        # rubocop:disable Style/IfUnlessModifier
        if cleaned.start_with?("From ")
          cleaned = cleaned.sub(/^From .*[\r\n]*/, "")
        end
        # rubocop:enable Style/IfUnlessModifier
        cleaned
      end

      # @param serialized [String] the on-disk version of the message
      #
      # @return [Message] the original message
      def self.from_serialized(serialized)
        new(clean_serialized(serialized))
      end

      # Deserializes a message stored with the old (v3) quoting logic,
      # which incorrectly quoted all 'From' lines, not just 'From ' lines.
      def self.clean_serialized_v3(serialized)
        cleaned = serialized.gsub(/^>(>*From)/, "\\1")
        cleaned = cleaned.sub(/^From .*[\r\n]*/, "") if cleaned.start_with?("From ")
        cleaned
      end

      # @param serialized [String] the on-disk version of a v3 message
      #
      # @return [Message] the original message
      def self.from_serialized_v3(serialized)
        new(clean_serialized_v3(serialized))
      end

      # @return [String] the original message body
      attr_reader :supplied_body

      # @param supplied_body [String] the original RFC 2822 message text
      def initialize(supplied_body)
        @supplied_body = supplied_body.clone
      end

      # @return [String] the message with an initial 'From ADDRESS' line
      def to_serialized
        # Build the entry from bytes rather than characters.
        #
        # `from` is derived from the parsed headers and stays ASCII-8BIT when
        # the header carries raw 8-bit bytes, e.g. a Latin-1 sender name.
        # Joining that with a UTF-8 body raises Encoding::CompatibilityError,
        # and so does "From #{from}\n" on its own, because interpolating into
        # a UTF-8 literal converts just as concatenation does.
        #
        # An mbox file is a byte stream and Mbox#append opens it in binary
        # mode, so joining in ASCII-8BIT preserves the original bytes exactly
        # and cannot raise. Messages that are plain ASCII or valid UTF-8
        # serialize to identical bytes as before.
        serialized = +"".b
        serialized << "From ".b
        serialized << from.to_s.b
        serialized << "\n".b
        serialized << mboxrd_body.b
        serialized
      end

      # @return [Date, nil] the date of the message
      def date
        parsed.date
      rescue StandardError
        nil
      end

      # @return [String] the message's subject line
      def subject
        parsed.subject
      end

      # @return [String] the original message ready for transmission to an IMAP server
      def imap_body
        supplied_body.gsub(/(?<!\r)\n/, "\r\n")
      end

      private

      def parsed
        @parsed ||= Mail.new(supplied_body)
      end

      def from
        @from ||=
          begin
            from = best_from.dup
            from << " #{asctime}" if asctime != ""
            from
          end
      end

      def best_from
        return first_from if first_from
        return parsed.sender if parsed.sender
        return parsed.envelope_from if parsed.envelope_from
        return parsed.return_path if parsed.return_path

        ""
      end

      def first_from
        return nil if !parsed.from.is_a?(Enumerable)

        parsed.from.find { |from| from }
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
        body.gsub(/\n(>*From )/, "\n>\\1")
      end

      def asctime
        @asctime ||= date ? date.asctime : ""
      end
    end
  end
end
