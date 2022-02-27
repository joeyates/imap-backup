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
      Imap::Backup::Serializer,
      uids: uids,
      each_message: each_message
    )
  end
  let(:uids) { ["123"] }
  let(:each_message) { [[123, message]] }
  let(:message) do
    instance_double(
      Email::Mboxrd::Message,
      date: Date.today,
      subject: message_subject,
      supplied_body: "Supplied"
    )
  end
  let(:message_subject) { "Ciao" }
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
    before { subject.list(email, "bar") }

    it "lists downloaded emails" do
      expect(Kernel).to have_received(:puts).with(/Ciao/)
    end

    context "when the subject line is too long" do
      let(:message_subject) { "A" * 70 }

      it "is shortened" do
        expect(Kernel).to have_received(:puts).with(/\sA{57}\.\.\./)
      end
    end
  end

  describe "show" do
    before { subject.show(email, "bar", uids.join(",")) }

    it "prints a downloaded email" do
      expect(Kernel).to have_received(:puts).with("Supplied")
    end

    context "when more than one email is requested" do
      let(:uids) { %w(123 456) }
      let(:each_message) { [[123, message], [456, message]] }

      it "prints a header" do
        expect(Kernel).to have_received(:puts).with(/\| UID: 123 /)
      end
    end
  end
end
