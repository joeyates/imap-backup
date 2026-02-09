require "highline"

require "imap/backup/setup"

module HighLineTestHelpers
  def prepare_highline
    @input = instance_double(IO, eof?: false, gets: nil)
    @output = StringIO.new
    Imap::Backup::Setup.highline = HighLine.new(@input, @output)
    [@input, @output]
  end

  def set_highline_input(*lines)
    allow(@input).to receive(:gets).and_return(*lines.map { |line| "#{line}\n" })
  end
end
