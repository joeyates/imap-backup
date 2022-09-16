require "net/imap"

module Imap::Backup
  describe Logger do
    describe ".setup_logging" do
      let(:options) { {} }

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
        described_class.setup_logging options
      end

      it "sets logger level to info" do
        expect(described_class.logger.level).to eq(::Logger::Severity::INFO)
      end

      it "unsets the Net::IMAP debug flag" do
        expect(Net::IMAP.debug).to be false
      end

      context "when verbose is passed" do
        let(:options) { {verbose: true} }

        it "sets logger level to debug" do
          expect(described_class.logger.level).to eq(::Logger::Severity::DEBUG)
        end

        it "sets the Net::IMAP debug flag" do
          expect(Net::IMAP.debug).to be true
        end
      end

      context "when quiet is passed" do
        let(:options) { {quiet: true} }

        it "sets logger level to unknown" do
          expect(described_class.logger.level).to eq(::Logger::Severity::UNKNOWN)
        end

        it "unsets the Net::IMAP debug flag" do
          expect(Net::IMAP.debug).to be false
        end
      end

      context "when quiet and verbose are passed" do
        let(:options) { {quiet: true, verbose: true} }

        it "sets logger level to unknown" do
          expect(described_class.logger.level).to eq(::Logger::Severity::UNKNOWN)
        end

        it "unsets the Net::IMAP debug flag" do
          expect(Net::IMAP.debug).to be false
        end
      end
    end
  end
end
