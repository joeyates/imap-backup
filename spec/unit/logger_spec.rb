require "stringio"
require "imap/backup/logger"

module Imap::Backup
  RSpec.describe Logger do
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

      let(:options) { {ciao: true} }
      let!(:result) { described_class.setup_logging(options) }

      it "sets logger level to info" do
        expect(described_class.logger.level).to eq(::Logger::Severity::INFO)
      end

      it "unsets the Net::IMAP debug flag" do
        expect(Net::IMAP.debug).to be false
      end

      it "returns options" do
        expect(result).to eq({ciao: true})
      end

      context "when logger-related options are passed" do
        let(:options) { {ciao: true, quiet: true, verbose: [true]} }

        it "excludes them and returns other options" do
          expect(result).to eq({ciao: true})
        end
      end

      context "when one verbose flag is passed" do
        let(:options) { {verbose: [true]} }

        it "sets logger level to debug" do
          expect(described_class.logger.level).to eq(::Logger::Severity::DEBUG)
        end
      end

      context "when two verbose flags are passed" do
        let(:options) { {verbose: [true, true]} }

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
        let(:options) { {quiet: true, verbose: [true]} }

        it "sets logger level to unknown" do
          expect(described_class.logger.level).to eq(::Logger::Severity::UNKNOWN)
        end

        it "unsets the Net::IMAP debug flag" do
          expect(Net::IMAP.debug).to be false
        end
      end
    end

    describe ".sanitize_stderr" do
      let(:sanitizer) { instance_double(Text::Sanitizer) }

      before do
        allow(Text::Sanitizer).to receive(:new).with($stdout) { sanitizer }
        allow(sanitizer).to receive(:flush)
        allow(sanitizer).to receive(:write)
        @original_stderr = $stderr
      end

      it "yields with the sanitized stderr" do
        yielded = nil

        described_class.sanitize_stderr do
          yielded = $stderr
        end

        expect(yielded).to be(sanitizer)
      end

      it "restores stderr after the block" do
        described_class.sanitize_stderr {}

        expect($stderr).to be(@original_stderr)
      end

      it "flushes the sanitizer" do
        expect(sanitizer).to receive(:flush)

        described_class.sanitize_stderr {}
      end
    end

    describe ".count" do
      it "starts from one" do
        expect(described_class.count([])).to eq(1)
      end

      it "increments for true flags" do
        expect(described_class.count([true, true])).to eq(3)
      end

      it "decrements for false flags" do
        expect(described_class.count([false, false])).to eq(-1)
      end
    end
  end
end
