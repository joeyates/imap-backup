module Imap::Backup
  describe CLI::Mirror do
    subject { described_class.new(source_email, destination_email, **options) }

    let(:source_email) { "source" }
    let(:destination_email) { "destination" }
    let(:options) { {} }
    let(:mirror) { instance_double(Mirror, run: nil) }
    let(:config) { instance_double(Configuration, accounts: [source_account, destination_account]) }
    let(:source_account) do
      instance_double(
        Account, "source_account",
        username: "source",
        mirror_mode: source_mirror_mode
      )
    end
    let(:source_mirror_mode) { true }
    let(:destination_account) do
      instance_double(
        Account, "destination_account",
        username: "destination"
      )
    end
    let(:backup) { instance_double(CLI::Backup, "backup_1", run: nil) }
    let(:folder_enumerator) { instance_double(CLI::FolderEnumerator) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(CLI::Backup).to receive(:new) { backup }
      allow(Mirror).to receive(:new) { mirror }
      allow(CLI::FolderEnumerator).to receive(:new) { folder_enumerator }
      allow(folder_enumerator).to receive(:each).and_yield("serializer", "folder")
    end

    it_behaves_like(
      "an action that requires an existing configuration",
      action: ->(subject) { subject.run }
    )

    context "when the accounts are the same" do
      let(:destination_email) { source_email }

      it "fails" do
        expect { subject.run }.to raise_error(RuntimeError, /same/)
      end
    end

    context "when the source account does not exist" do
      let(:source_email) { "unknown" }

      it "fails" do
        expect { subject.run }.to raise_error(RuntimeError, /does not exist/)
      end
    end

    context "when the destination account does not exist" do
      let(:destination_email) { "unknown" }

      it "fails" do
        expect { subject.run }.to raise_error(RuntimeError, /does not exist/)
      end
    end

    context "when the source account is not in mirror mode" do
      let(:source_mirror_mode) { false }

      before { allow(Logger.logger).to receive(:warn) }

      it "warns" do
        subject.run

        expect(Logger.logger).to have_received(:warn).with(/not set up/)
      end
    end

    it "runs backup on the source" do
      subject.run

      expect(backup).to have_received(:run)
    end

    it "mirrors each folder" do
      subject.run

      expect(mirror).to have_received(:run)
    end

    %i[
      destination_delimiter
      destination_prefix
      config
      source_delimiter
      source_prefix
    ].each do |option|
      it "accepts a #{option} option" do
        opts = options.merge(option => "foo")
        described_class.new("source", "destination", **opts)
      end
    end
  end
end
