module Imap::Backup
  describe Account::Connection::BackupFolders do
    subject { described_class.new(client: client, account: account) }

    let(:account) do
      instance_double(
        Account,
        folders: account_folders,
        connection: connection,
        folder_blacklist: folder_blacklist
      )
    end
    let(:client) { instance_double(Client::Default) }
    let(:connection) { instance_double(Account::Connection) }
    let(:account_folders) { [{name: "foo"}] }
    let(:folder_blacklist) { false }
    let(:folder_names) do
      instance_double(Account::Connection::FolderNames, run: %w(foo bar baz))
    end
    let(:result) { subject.run }

    before do
      allow(Account::Connection::FolderNames).to receive(:new) { folder_names }
    end

    it "returns a folder for each configured folder" do
      expect(result.map(&:name)).to eq(%w(foo))
    end

    it "returns Account::Folders" do
      expect(result.first).to be_a(Account::Folder)
    end

    it "sets the connection" do
      expect(result.first.connection).to eq(connection)
    end

    context "when no folders are configured" do
      let(:account_folders) { nil }

      it "returns all online folders" do
        expect(result.map(&:name)).to eq(%w(foo bar baz))
      end
    end

    context "when the configured folders are an empty list" do
      let(:account_folders) { [] }

      it "returns all online folders" do
        expect(result.map(&:name)).to eq(%w(foo bar baz))
      end
    end

    context "when the folder_blacklist flag is set" do
      let(:folder_blacklist) { true }

      it "returns account folders except the configured folders" do
        expect(result.map(&:name)).to eq(%w(bar baz))
      end

      context "when no folders are configured" do
        let(:account_folders) { nil }

        it "returns all online folders" do
          expect(result.map(&:name)).to eq(%w(foo bar baz))
        end
      end

      context "when the configured folders are an empty list" do
        let(:account_folders) { [] }

        it "returns all online folders" do
          expect(result.map(&:name)).to eq(%w(foo bar baz))
        end
      end
    end
  end
end
