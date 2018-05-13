module HighLineTestHelpers
  def prepare_highline
    @input = double("stdin", eof?: false, gets: "q\n")
    @output = StringIO.new
    Imap::Backup::Configuration::Setup.highline = HighLine.new(@input, @output)
    [@input, @output]
  end
end
