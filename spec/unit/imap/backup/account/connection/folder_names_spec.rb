module Imap::Backup
  describe Account::Connection::FolderNames do
    subject { described_class.new(client: client, account: account) }

    let(:account) { instance_double(Account, username: "username") }
    let(:client) { instance_double(Client::Default, list: folders) }
    let(:folders) { %w[folder] }

    it "returns the list of folders" do
      expect(subject.run).to eq(folders)
    end

    context "when the list is empty" do
      let(:folders) { [] }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(RuntimeError, /Unable to get folder list/)
      end
    end
  end
end
