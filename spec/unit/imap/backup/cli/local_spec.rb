describe Imap::Backup::CLI::Local do
  let(:accounts) do
    instance_double(
      Imap::Backup::CLI::Accounts,
      find: ->(&block) { [account].find { |a| block.call(a) } }
    )
  end
  let(:account) do
    instance_double(
      Imap::Backup::Account,
      username: email,
      marked_for_deletion?: false,
      modified?: false
    )
  end
  let(:connection) do
    instance_double(
      Imap::Backup::Account::Connection,
      local_folders: local_folders
    )
  end
  let(:local_folders) { [[serializer, folder]] }
  let(:folder) { instance_double(Imap::Backup::Account::Folder, name: "bar") }
  let(:serializer) do
    instance_double(
      Imap::Backup::Serializer::Mbox,
      uids: uids,
      each_message: [[123, message]]
    )
  end
  let(:uids) { ["123"] }
  let(:message) do
    instance_double(
      Email::Mboxrd::Message,
      date: Date.today,
      subject: "Ciao",
      supplied_body: "Supplied"
    )
  end
  let(:email) { "foo@example.com" }

  before do
    allow(Kernel).to receive(:puts)
    allow(Imap::Backup::CLI::Accounts).to receive(:new) { accounts }
    allow(Imap::Backup::Account::Connection).to receive(:new) { connection }
    allow(Mail).to receive(:new) { mail }
    allow(accounts).to receive(:each).and_yield(account)
  end

  describe "accounts" do
    it "lists configured emails" do
      subject.accounts

      expect(Kernel).to have_received(:puts).with(email)
    end
  end

  describe "folders" do
    it "lists downloaded folders in quotes" do
      subject.folders(email)

      expect(Kernel).to have_received(:puts).with(%("bar"))
    end
  end

  describe "list" do
    it "lists downloaded emails" do
      subject.list(email, "bar")

      expect(Kernel).to have_received(:puts).with(/Ciao/)
    end
  end

  describe "show" do
    it "prints a downloaded email" do
      subject.show(email, "bar", "123")

      expect(Kernel).to have_received(:puts).with("Supplied")
    end
  end
end
