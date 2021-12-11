describe Imap::Backup::CLI::Local do
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
    allow(Imap::Backup::Configuration::List).to receive(:new) { list }
    allow(Imap::Backup::Account::Connection).to receive(:new) { connection }
    allow(Mail).to receive(:new) { mail }
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
