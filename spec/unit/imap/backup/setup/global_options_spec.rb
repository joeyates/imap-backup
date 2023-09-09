require "imap/backup/setup/global_options"

module Imap::Backup
  RSpec.describe Setup::GlobalOptions do
    include HighLineTestHelpers

    subject { described_class.new(config: config) }

    let(:config) do
      instance_double(
        Configuration,
        download_strategy: "delay_metadata",
        download_strategy_modified: download_strategy_modified
      )
    end
    let!(:highline_streams) { prepare_highline }
    let(:input) { highline_streams[0] }
    let(:output) { highline_streams[1] }
    let(:download_strategy_chooser) do
      instance_double(Setup::GlobalOptions::DownloadStrategyChooser, run: nil)
    end
    let(:download_strategy_modified) { false }

    before do
      allow(Kernel).to receive(:system)
      allow(Setup::GlobalOptions::DownloadStrategyChooser).
        to receive(:new) { download_strategy_chooser }
    end

    it "clears the screen" do
      subject.run

      expect(Kernel).to have_received(:system).with("clear")
    end

    it "shows the menu" do
      subject.run

      expect(output.string).to match(/Global Options/)
    end

    it "shows the current download strategy" do
      subject.run

      expect(output.string).to match(/currently: 'delay writing metadata'/)
    end

    context "when the download strategy has been modified" do
      let(:download_strategy_modified) { true }

      it "shows a modified indicator" do
        subject.run

        expect(output.string).to match(/currently: 'delay writing metadata'\) \*/)
      end
    end

    it "accepts choices" do
      allow(input).to receive(:gets).and_return("1\n", "q\n")

      subject.run

      expect(download_strategy_chooser).to have_received(:run)
    end
  end
end
