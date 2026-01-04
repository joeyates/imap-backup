require "imap/backup/cli/local/check"

module Imap::Backup
  RSpec.describe CLI::Local::Check do
    subject { described_class.new(options) }

    let(:options) { {} }
    let(:config) { instance_double(Configuration) }
    let(:account) { instance_double(Account, username: "user@example.com") }
    let(:serializer) do
      instance_double(
        Serializer,
        folder: "INBOX",
        delete: nil,
        check_integrity!: nil
      )
    end
    let(:folder) { instance_double(Account::Folder) }
    let(:serialized_folders) { instance_double(Account::SerializedFolders) }

    before do
      allow(subject).to receive(:load_config) { config }
      allow(subject).to receive(:requested_accounts).with(config) { [account] }
      allow(Account::SerializedFolders).to receive(:new).
        with(account: account) { serialized_folders }
      allow(serialized_folders).to receive(:map) do |&block|
        [block.call(serializer, folder)]
      end
      allow(Kernel).to receive(:puts)
    end

    context "when deleting corrupt folders" do
      let(:options) { {delete_corrupt: true} }
      let(:error) { Serializer::FolderIntegrityError.new("Broken folder") }

      before do
        allow(serializer).to receive(:check_integrity!).and_raise(error)
        allow(serializer).to receive(:delete)

        subject.run
      end

      it "deletes the corrupt folder" do
        expect(serializer).to have_received(:delete)
      end

      it "prints the deletion notice" do
        expect(Kernel).to have_received(:puts).
          with(/\tINBOX: Broken folder and has been deleted/)
      end
    end

    context "when corrupt folders are kept" do
      let(:error) { Serializer::FolderIntegrityError.new("Bad folder") }

      before do
        allow(serializer).to receive(:check_integrity!).and_raise(error)
        allow(serializer).to receive(:delete)

        subject.run
      end

      it "does not delete the folder" do
        expect(serializer).not_to have_received(:delete)
      end

      it "reports the integrity error" do
        expect(Kernel).to have_received(:puts).
          with(/\tINBOX: Bad folder/)
      end
    end

    context "when JSON format is requested" do
      let(:options) { {format: "json"} }

      before do
        allow(serializer).to receive(:check_integrity!)

        subject.run
      end

      it "prints JSON" do
        expect(Kernel).to have_received(:puts).
          with(/"account":"user@example.com"/)
      end
    end
  end
end
