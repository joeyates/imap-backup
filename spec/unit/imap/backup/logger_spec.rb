require "net/imap"

module Imap::Backup
  describe Logger do
    describe ".setup_logging" do
      let(:config) { instance_double(Configuration::Store, debug?: debug) }

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
        allow(Configuration::Store).to receive(:new) { config }
        described_class.setup_logging
      end

      context "when config.debug?" do
        let(:debug) { true }

        it "sets logger level to debug" do
          expect(described_class.logger.level).to eq(::Logger::Severity::DEBUG)
        end

        it "sets the Net::IMAP debug flag" do
          expect(Net::IMAP.debug).to be_a(TrueClass)
        end
      end

      context "when not config.debug?" do
        let(:debug) { false }

        it "sets logger level to error" do
          expect(described_class.logger.level).to eq(::Logger::Severity::ERROR)
        end

        it "sets the Net::IMAP debug flag" do
          expect(Net::IMAP.debug).to be_a(FalseClass)
        end
      end
    end
  end
end
