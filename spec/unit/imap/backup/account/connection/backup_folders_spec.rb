module Imap::Backup
  describe Account::Connection::BackupFolders do
    subject { described_class.new(client: client, account: account) }

    let(:account) { instance_double(Account, folders: account_folders, connection: connection) }
    let(:client) { instance_double(Client::Default) }
    let(:connection) { instance_double(Account::Connection) }
    let(:account_folders) { [{name: "foo"}] }
    let(:folder_names) { instance_double(Account::Connection::FolderNames, run: ["imap_folder"]) }
    let(:result) { subject.run }

    before do
      allow(Account::Connection::FolderNames).to receive(:new) { folder_names }
    end

    it "returns a folder for each configured folder" do
      expect(result.count).to eq(1)
    end

    it "returns Account::Folders" do
      expect(result.first).to be_a(Account::Folder)
    end

    it "sets the connection" do
      expect(result.first.connection).to eq(connection)
    end

    it "sets the name" do
      expect(result.first.name).to eq("foo")
    end

    context "when the configured folders are missing" do
      let(:account_folders) { nil }

      it "uses the online folders" do
        expect(result.first.name).to eq("imap_folder")
      end
    end

    context "when the configured folders are an empty list" do
      let(:account_folders) { [] }

      it "uses the online folders" do
        expect(result.first.name).to eq("imap_folder")
      end
    end
  end
end
