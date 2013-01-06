require 'mail'

module Email
  module Mbox
    class Message
      def initialize(body)
        @body = body
      end

      def to_mbox
        from = parsed.envelope.from
        prefixed_gt = @body.gsub("\nFrom", "\n>From")
        'From ' + from + "\n" + prefixed_gt
      end

      private

      def parsed
        @parsed ||= Mail.new(@body)
      end
    end
  end
end

