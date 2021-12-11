describe Imap::Backup::CLI::Utils do
  let(:list) do
    instance_double(Imap::Backup::Configuration::List, accounts: accounts)
  end
  let(:accounts) { [{username: email}] }
  let(:connection) do
    instance_double(
      Imap::Backup::Account::Connection,
      local_folders: local_folders
    )
  end
  let(:local_folders) { [[serializer, folder]] }
  let(:folder) do
    instance_double(
      Imap::Backup::Account::Folder,
      exist?: true,
      name: "name",
      uid_validity: "uid_validity",
      uids: ["123"]
    )
  end
  let(:serializer) do
    instance_double(
      Imap::Backup::Serializer::Mbox,
      uids: ["123", "456"],
      apply_uid_validity: nil
    )
  end
  let(:email) { "foo@example.com" }

  before do
    allow(Imap::Backup::Configuration::List).to receive(:new) { list }
    allow(Imap::Backup::Account::Connection).to receive(:new) { connection }
  end

  describe "ignore_history" do
    it "ensures the local UID validity matches the server"

    it "fills the local folder with fake emails" do
      subject.ignore_history(email)

      TODO
    end
  end
end
