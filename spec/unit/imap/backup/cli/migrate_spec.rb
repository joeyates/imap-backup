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
    let(:migrator) { instance_double(Migrator, run: nil) }
    let(:imap_pathname) { Pathname.new("path/foo.imap") }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Pathname).to receive(:glob).and_yield(imap_pathname)
      allow(Migrator).to receive(:new) { migrator }
      allow(Account::Folder).to receive(:new).and_call_original
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

    context "when source_prefix is supplied" do
      let(:options) { {source_prefix: "src/"} }
      let(:imap_pathname) { Pathname.new("path/src/foo.imap") }

      it "removes the prefix" do
        subject.run

        expect(Account::Folder).to have_received(:new).with(anything, "foo")
      end
    end

    context "when destination_prefix is supplied" do
      let(:options) { {destination_prefix: "dest/"} }
      let(:imap_pathname) { Pathname.new("path/foo.imap") }

      it "removes the prefix" do
        subject.run

        expect(Account::Folder).to have_received(:new).with(anything, "dest/foo")
      end
    end
  end
end
