module Imap::Backup
  describe CLI::Local do
    let(:account) do
      instance_double(
        Account,
        username: email,
        marked_for_deletion?: false,
        modified?: false
      )
    end
    let(:connection) do
      instance_double(
        Account::Connection,
        local_folders: local_folders
      )
    end
    let(:local_folders) { [[serializer, folder]] }
    let(:folder) { instance_double(Account::Folder, name: "bar") }
    let(:serializer) do
      instance_double(
        Serializer,
        uids: uids,
        each_message: each_message
      )
    end
    let(:uids) { ["123"] }
    let(:each_message) { [message] }
    let(:message) do
      instance_double(
        Imap::Backup::Serializer::Message,
        uid: 123,
        date: Date.today,
        subject: message_subject,
        body: "Supplied"
      )
    end
    let(:message_subject) { "Ciao" }
    let(:email) { "foo@example.com" }
    let(:config) { instance_double(Configuration, accounts: [account]) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Kernel).to receive(:puts)
      allow(Account::Connection).to receive(:new) { connection }
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
        let(:message1) do
          instance_double(
            Imap::Backup::Serializer::Message,
            uid: 456,
            body: "Message 2"
          )
        end
        let(:each_message) { [message, message1] }

        it "prints a header" do
          expect(Kernel).to have_received(:puts).with(/\| UID: 123 /)
        end
      end
    end
  end
end
