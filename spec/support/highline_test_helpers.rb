require "highline"
require "timeout"

require "imap/backup/setup"

module HighLineTestHelpers
  def prepare_highline
    @input = instance_double(IO, eof?: false, gets: nil)
    @output = StringIO.new
    Imap::Backup::Setup.highline = HighLine.new(@input, @output)
    [@input, @output]
  end

  def read_highline_output
    @output.rewind
    @output.read
  end

  def set_highline_input(*lines)
    supplied =
      lines.
      each.
      with_index(1).
      map { |line, index| %(#{index}: "#{line.chomp}") }.
      join("\n")

    inputs = lines.dup

    allow(@input).to receive(:gets) do
      if inputs.empty?
        message = <<~MSG
          No more highline input lines available.

          Input lines provided:
          #{supplied}

          Output so far:
          #{read_highline_output}
        MSG
        raise message
      end

      inputs.shift
    end
  end

  def await_highline_completion(options, &block)
    timeout = options.fetch(:timeout, 2)
    Timeout.timeout(timeout, Timeout::ExitException) do
      block.call
    rescue Timeout::ExitException
      message = <<~MSG
        HighLine did not complete within #{timeout} seconds.

        Output so far:
        #{read_highline_output}
      MSG
      raise message
    end
  end
end
