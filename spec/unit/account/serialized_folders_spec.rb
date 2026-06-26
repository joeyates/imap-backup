require "imap/backup/account/serialized_folders"

module Imap::Backup
  RSpec.describe Account::SerializedFolders do
    subject { described_class.new(account: account) }

    let(:account) do
      instance_double(
        Account,
        client: client,
        local_path: "/backups"
      )
    end
    let(:client) { instance_double(Client::Default) }
    let(:paths) { [Pathname.new("/backups/INBOX.imap")] }
    let(:serializer) { instance_double(Serializer) }
    let(:folder) { instance_double(Account::Folder) }
    let(:directory_maker) { instance_double(Serializer::DirectoryMaker, run: nil) }

    before do
      allow(Pathname).to receive(:glob) { paths }
      allow(Serializer).to receive(:new) { serializer }
      allow(Serializer::DirectoryMaker).to receive(:new) { directory_maker }
      allow(Account::Folder).to receive(:new) { folder }
    end

    describe "#each" do
      it "returns an enumerator when no block is supplied" do
        enumerator = subject.each

        expect(enumerator.to_a).to eq([[serializer, folder]])
      end

      it "yields serializers and folders" do
        yielded = subject.map do |serializer_value, folder_value|
          [serializer_value, folder_value]
        end

        expect(yielded).to eq([[serializer, folder]])
      end
    end

    describe "#each_key" do
      it "returns an enumerator when no block is supplied" do
        enumerator = subject.each_key

        expect(enumerator.to_a).to eq([serializer])
      end
    end

    describe "#each_value" do
      it "returns an enumerator when no block is supplied" do
        enumerator = subject.each_value

        expect(enumerator.to_a).to eq([folder])
      end
    end

    context "when a serialized folder name contains escaped characters" do
      let(:paths) { [Pathname.new("/backups/Notes 10%3a;00.imap")] }

      it "decodes the name when building the folder" do
        subject.each_value { |_| }

        expect(Account::Folder).
          to have_received(:new).with(client, "Notes 10:00")
      end
    end
  end
end
