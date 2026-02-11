require "imap/backup/setup/global_options/download_strategy_chooser"
require "imap/backup/translator"

module Imap::Backup
  RSpec.describe Setup::GlobalOptions::DownloadStrategyChooser do
    include HighLineTestHelpers

    subject { described_class.new(config: config) }

    let(:config) do
      instance_double(
        Configuration,
        download_strategy: "a",
        "download_strategy=": nil
      )
    end
    let!(:highline_streams) { prepare_highline }
    let(:input) { highline_streams[0] }
    let(:output) { highline_streams[1] }

    before do
      Translator.new.setup
      allow(Kernel).to receive(:system)
      allow(Kernel).to receive(:puts)
      set_highline_input("q\n")
    end

    it "clears the screen" do
      subject.run

      expect(Kernel).to have_received(:system).with("clear")
    end

    it "shows the menu" do
      subject.run

      expect(output.string).to match(/Choose a Download Strategy/)
    end

    it "accepts choices" do
      set_highline_input("2\n", "q\n")

      subject.run

      expect(config).to have_received(:download_strategy=).with("delay_metadata")
    end

    it "shows help" do
      set_highline_input("help\n", "", "q\n")

      subject.run

      expect(Kernel).to have_received(:puts).with(/This setting/)
    end

    context "when a strategy matches the current value" do
      let(:config) do
        instance_double(
          Configuration,
          download_strategy: "direct",
          "download_strategy=": nil
        )
      end

      it "marks the entry as current" do
        set_highline_input("q\n")

        subject.run

        expect(output.string).to match(/write straight to disk <- current/)
      end
    end
  end
end
