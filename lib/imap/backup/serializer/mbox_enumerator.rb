module Imap::Backup
  class Serializer::MboxEnumerator
    attr_reader :mbox_pathname

    def initialize(mbox_pathname)
      @mbox_pathname = mbox_pathname
    end

    def each
      return enum_for(:each) if !block_given?

      File.open(mbox_pathname, "rb") do |f|
        lines = []

        loop do
          line = f.gets
          break if !line

          if line.start_with?("From ")
            yield lines.join if lines.count.positive?
            lines = [line]
          else
            lines << line
          end
        end

        yield lines.join if lines.count.positive?
      end
    end
  end
end
