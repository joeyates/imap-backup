require 'mail'

module Email; end

module Email::Mboxrd
  class Message
    def initialize(body)
      @body = body.clone
      @body.force_encoding('binary') if RUBY_VERSION >= '1.9.0'
    end

    def to_s
      'From ' + from + "\n" + body + "\n"
    end

    private

    def parsed
      @parsed ||= Mail.new(@body)
    end

    def from
      parsed.from[0] + ' ' + asctime
    end

    def body
      mbox = @body.gsub(/\n(>*From)/, "\n>\\1")
      mbox += "\n" unless mbox.end_with?("\n")
      mbox
    end

    def asctime
      parsed.date.asctime
    end
  end
end
