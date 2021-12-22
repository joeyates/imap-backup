module Imap::Backup
  describe CLI::Utils do
    let(:list) do
      instance_double(Configuration::List, accounts: accounts)
    end
    let(:accounts) { [{username: email}] }
    let(:connection) do
      instance_double(
        Account::Connection,
        local_folders: local_folders
      )
    end
    let(:local_folders) { [[serializer, folder]] }
    let(:folder) do
      instance_double(
        Account::Folder,
        exist?: true,
        name: "name",
        uid_validity: "uid_validity",
        uids: %w(123 456)
      )
    end
    let(:serializer) do
      instance_double(
        Serializer::Mbox,
        uids: %w(123 789),
        apply_uid_validity: nil,
        save: nil
      )
    end
    let(:email) { "foo@example.com" }

    before do
      allow(Configuration::List).to receive(:new) { list }
      allow(Account::Connection).to receive(:new) { connection }
    end

    describe "ignore_history" do
      it "ensures the local UID validity matches the server" do
        subject.ignore_history(email)

        expect(serializer).to have_received(:apply_uid_validity).with("uid_validity")
      end

      it "fills the local folder with fake emails" do
        subject.ignore_history(email)

        expect(serializer).to have_received(:save).with("456", /From: fake@email.com/)
      end
    end
  end
end
