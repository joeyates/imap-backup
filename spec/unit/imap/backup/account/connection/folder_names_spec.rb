module Imap::Backup
  describe Account::Connection::FolderNames do
    subject { described_class.new(client: client) }

    let(:client) do
      instance_double(Client::Default, list: folders, username: "username")
    end
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
