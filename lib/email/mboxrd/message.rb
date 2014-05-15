require 'mail'

module Email; end

module Email::Mboxrd
  class Message
    attr_reader :supplied_body

    def initialize(supplied_body)
      @supplied_body = supplied_body.clone
      @supplied_body.force_encoding('binary') if RUBY_VERSION >= '1.9.0'
    end

    def to_s
      'From ' + from + "\n" + mboxrd_body + "\n"
    end

    private

    def parsed
      @parsed ||= Mail.new(supplied_body)
    end

    def from
      parsed.from[0] + ' ' + asctime
    end

    def mboxrd_body
      return @mboxrd_body if @mboxrd_body
      @mboxrd_body = supplied_body.gsub(/\n(>*From)/, "\n>\\1")
      @mboxrd_body += "\n" unless @mboxrd_body.end_with?("\n")
      @mboxrd_body
    end

    def asctime
      parsed.date.asctime
    end
  end
end
