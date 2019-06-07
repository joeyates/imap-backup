require "ostruct"
require "imap/backup"

describe Imap::Backup do
  describe ".setup_logging" do
    let!(:previous) { described_class.logger.level }

    before { described_class.setup_logging(config) }
    after { described_class.logger.level = previous }

    context "when config.debug?" do
      let(:config) { OpenStruct.new(debug?: true) }

      it "sets logger level to debug" do
        expect(described_class.logger.level).to eq(::Logger::Severity::DEBUG)
      end
    end

    context "when not config.debug?" do
      let(:config) { OpenStruct.new(debug?: false) }

      it "sets logger level to debug" do
        expect(described_class.logger.level).to eq(::Logger::Severity::ERROR)
      end
    end
  end
end
