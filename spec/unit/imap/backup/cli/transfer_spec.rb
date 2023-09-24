require "imap/backup/cli/transfer"

module Imap::Backup
  RSpec.describe CLI::Transfer do
    subject { described_class.new(:migrate, source, destination, options) }

    let(:source) { "source" }
    let(:destination) { "destination" }
    let(:options) { {} }
    let(:config) { instance_double(Configuration, accounts: [account1, account2]) }
    let(:account1) { instance_double(Account, username: "source", local_path: "account1_path") }
    let(:account2) { instance_double(Account, username: "destination") }
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

    it_behaves_like(
      "an action that requires an existing configuration",
      action: ->(subject) { subject.run }
    )

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

    %i[
      automatic_namespaces
      config
      destination_delimiter
      destination_prefix
      reset
      source_delimiter
      source_prefix
    ].each do |option|
      it "accepts a #{option} option" do
        opts = options.merge(option => "foo")
        described_class.new(:migrate, source, destination, **opts)
      end
    end

    context "when the automatic_namespaces option is given" do
      it "uses the values from the servers"
      it "fails if delims or prefixes are given"
    end

    context "when the automatic_namespaces option is not given" do
      it "defaults to delims and prefixes"
      it "uses supplied delims and prefixes"
    end
  end
end
