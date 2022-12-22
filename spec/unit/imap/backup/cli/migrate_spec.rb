module Imap::Backup
  describe CLI::Migrate do
    subject { described_class.new(source, destination, **options) }

    let(:source) { "source" }
    let(:destination) { "destination" }
    let(:options) { {} }
    let(:config) { instance_double(Configuration, accounts: [account1, account2]) }
    let(:account1) { instance_double(Account, username: "source", local_path: "path") }
    let(:account2) { instance_double(Account, username: "destination", connection: connection) }
    let(:connection) { instance_double(Account::Connection) }
    let(:serializer) { instance_double(Serializer) }
    let(:folder) { instance_double(Account::Folder) }
    let(:migrator) { instance_double(Migrator, run: nil) }
    let(:folder_enumerator) { instance_double(CLI::FolderEnumerator) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Migrator).to receive(:new) { migrator }
      allow(CLI::FolderEnumerator).to receive(:new) { folder_enumerator }
      allow(folder_enumerator).to receive(:each).and_yield(serializer, folder)
    end

    it "migrates each folder" do
      subject.run

      expect(migrator).to have_received(:run)
    end

    context "when source and destination emails are the same" do
      let(:destination) { "source" }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(RuntimeError, /cannot be the same/)
      end
    end

    context "when the source account is not found" do
      let(:source) { "unknown" }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(RuntimeError, /does not exist/)
      end
    end

    context "when the destination account is not found" do
      let(:destination) { "unknown" }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(RuntimeError, /does not exist/)
      end
    end

    context "options" do
      %i[
        destination_delimiter
        destination_email
        destination_prefix
        config_path
        source_delimiter
        source_email
        source_prefix
      ].each do |option|
        let(:options) { super().merge(option => "foo") }

        it "accepts a #{option} option" do
          subject
        end
      end
    end
  end
end
