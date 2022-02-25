module Imap::Backup
  describe CLI::Utils do
    let(:accounts) do
      instance_double(
        CLI::Accounts,
        find: ->(&block) { [account].find { |a| block.call(a) } }
      )
    end
    let(:account) { instance_double(Account, username: email) }
    let(:connection) do
      instance_double(
        Account::Connection,
        account: account,
        backup_folders: [folder]
      )
    end
    let(:account) do
      instance_double(
        Account,
        local_path: "path"
      )
    end
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
        Serializer,
        uids: %w(123 789),
        apply_uid_validity: nil,
        append: nil
      )
    end
    let(:email) { "foo@example.com" }

    before do
      allow(CLI::Accounts).to receive(:new) { accounts }
      allow(Account::Connection).to receive(:new) { connection }
      allow(Serializer).to receive(:new) { serializer }
    end

    describe "ignore_history" do
      it "ensures the local UID validity matches the server" do
        subject.ignore_history(email)

        expect(serializer).to have_received(:apply_uid_validity).with("uid_validity")
      end

      it "fills the local folder with fake emails" do
        subject.ignore_history(email)

        expect(serializer).to have_received(:append).with("456", /From: fake@email.com/)
      end
    end
  end
end
