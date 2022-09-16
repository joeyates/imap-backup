require "net/imap"

module Imap::Backup
  describe Logger do
    describe ".setup_logging" do
      around do |example|
        logger_previous = described_class.logger.level
        net_imap_previous = Net::IMAP.debug
        described_class.logger.level = 42
        Net::IMAP.debug = 42
        example.run
        Net::IMAP.debug = net_imap_previous
        described_class.logger.level = logger_previous
      end

      before do
        described_class.setup_logging ::Logger::Severity::ERROR
      end

      it "sets logger level to error" do
        expect(described_class.logger.level).to eq(::Logger::Severity::ERROR)
      end

      it "doesn't set the Net::IMAP debug flag" do
        expect(Net::IMAP.debug).to be_a(FalseClass)
      end
    end
  end
end
