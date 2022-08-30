module Imap::Backup
  class Serializer; end

  class Serializer::MboxEnumerator
    attr_reader :mbox_pathname

    def initialize(mbox_pathname)
      @mbox_pathname = mbox_pathname
    end

    def each(&block)
      return enum_for(:each) if !block

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

        block.call(lines.join) if lines.count.positive?
      end
    end

    def map(&block)
      return enum_for(:map) if !block

      each.map { |line| block.call(line) }
    end
  end
end
