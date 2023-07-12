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
    let(:serialized_folders) { instance_double(Account::SerializedFolders) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Kernel).to receive(:puts)
      allow(Mail).to receive(:new) { mail }
      allow(Account::SerializedFolders).to receive(:new) { serialized_folders }
    end

    describe "accounts" do
      it_behaves_like(
        "an action that requires an existing configuration",
        action: ->(subject) { subject.accounts }
      )

      it "lists configured emails" do
        subject.accounts

        expect(Kernel).to have_received(:puts).with(email)
      end
    end

    describe "folders" do
      before do
        allow(serialized_folders).to receive(:each).and_yield(serializer, folder)
      end

      it_behaves_like(
        "an action that requires an existing configuration",
        action: ->(subject) { subject.folders("email") }
      )

      it "lists downloaded folders in quotes" do
        subject.folders(email)

        expect(Kernel).to have_received(:puts).with(%("bar"))
      end
    end

    describe "list" do
      before do
        allow(serialized_folders).to receive(:find) { [serializer, folder] }
      end

      it_behaves_like(
        "an action that requires an existing configuration",
        action: ->(subject) { subject.list("email", "bar") }
      )

      it "lists downloaded emails" do
        subject.list(email, "bar")

        expect(Kernel).to have_received(:puts).with(/Ciao/)
      end

      context "when the subject line is too long" do
        let(:message_subject) { "A" * 70 }

        it "is shortened" do
          subject.list(email, "bar")

          expect(Kernel).to have_received(:puts).with(/\sA{57}\.\.\./)
        end
      end
    end

    describe "show" do
      before do
        allow(serialized_folders).to receive(:find) { [serializer, folder] }
      end

      it_behaves_like(
        "an action that requires an existing configuration",
        action: ->(subject) { subject.show("email", "bar", "1") }
      )

      it "prints a downloaded email" do
        subject.show(email, "bar", uids.join(","))

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
          subject.show(email, "bar", uids.join(","))

          expect(Kernel).to have_received(:puts).with(/\| UID: 123 /)
        end
      end
    end
  end
end
