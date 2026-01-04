require "imap/backup/client/default"

require "imap/backup/account"

module Imap::Backup
  RSpec.describe Client::Default do
    subject { described_class.new(account) }

    let(:password) { "secret" }
    let(:account) do
      instance_double(
        Account,
        username: username,
        password: password,
        server: "imap.example.com",
        connection_options: {}
      )
    end

    let(:username) { "me@example.com" }
    let(:imap) do
      instance_double(
        Net::IMAP,
        list: imap_folders,
        login: nil,
        disconnect: nil,
        select: nil,
        examine: nil
      )
    end
    let(:imap_folders) { [] }
    let(:logger) { instance_double(::Logger, debug: nil) }

    before do
      allow(Net::IMAP).to receive(:new) { imap }
      allow(Imap::Backup::Logger).to receive(:logger) { logger }
    end

    describe "#list" do
      context "when the server returns nothing" do
        let(:imap_folders) { nil }
        let(:username) { "user@mac.com" }

        it "is empty" do
          expect(subject.list).to eq([])
        end
      end

      context "with non-ASCII folder names" do
        let(:imap_folders) do
          [instance_double(Net::IMAP::MailboxList, attr: [], name: "Gel&APY-scht")]
        end

        it "converts them to UTF-8" do
          expect(subject.list).to eq(["Gelöscht"])
        end
      end

      context "when the provider is Apple" do
        let(:username) { "user@mac.com" }

        it "uses an empty string as provider root" do
          subject.list

          expect(imap).to have_received(:list).with("", "*")
        end
      end

      context "when the provider is not Apple" do
        let(:root_folder_info) do
          [instance_double(Net::IMAP::MailboxList, name: "/")]
        end

        before do
          allow(imap).to receive(:list).and_return(root_folder_info, imap_folders)
        end

        it "queries the server for the provider root" do
          subject.list

          expect(imap).to have_received(:list).with("", "")
        end
      end

      context "when the provider is GMail" do
        let(:username) { "me@gmail.com" }

        let(:imap_folders) do
          [
            instance_double(Net::IMAP::MailboxList, attr: [:Noselect], name: "[Gmail]"),
            instance_double(Net::IMAP::MailboxList, attr: [], name: "INBOX")
          ]
        end

        it "filters out NoSelect folders" do
          expect(subject.list).to eq(["INBOX"])
        end
      end

      context "when the provider is not GMail" do
        let(:imap_folders) do
          [
            instance_double(Net::IMAP::MailboxList, attr: [:Noselect], name: "Foo"),
            instance_double(Net::IMAP::MailboxList, attr: [], name: "INBOX")
          ]
        end

        it "filters out NoSelect folders" do
          expect(subject.list).to eq(%w(Foo INBOX))
        end
      end

      context "when the provider does not respond with its root" do
        before do
          allow(imap).to receive(:list) { [] }
        end

        it "fails" do
          expect do
            subject.list
          end.to raise_error(RuntimeError, /IMAP server did not return root folder/)
        end
      end
    end

    describe "#examine" do
      before do
        allow(imap).to receive(:examine)
        subject.examine("foo")
      end

      it "skips repeated calls on the same mailbox" do
        subject.examine("foo")

        expect(imap).to have_received(:examine).once
      end
    end

    describe "#select" do
      before do
        allow(imap).to receive(:select)
        subject.select("foo")
      end

      it "skips repeated calls on the same mailbox" do
        subject.select("foo")

        expect(imap).to have_received(:select).once
      end
    end

    describe "#login" do
      before do
        subject.login
      end

      it "passes the credentials to the server" do
        expect(imap).to have_received(:login).with(username, password)
      end

      it "logs the masked password" do
        expect(logger).to have_received(:debug).
          with("Logging in: #{username}/#{'x' * password.length}")
      end
    end

    describe "#reconnect" do
      before do
        allow(imap).to receive(:login)
        subject.reconnect
      end

      it "disconnects first" do
        expect(imap).to have_received(:disconnect)
      end

      it "logs in again" do
        expect(imap).to have_received(:login)
      end
    end

    describe "#username" do
      it "returns the account username" do
        expect(subject.username).to eq(username)
      end
    end

    describe "#disconnect" do
      before do
        subject.select("mailbox")
        subject.disconnect
      end

      it "disconnects the IMAP session" do
        expect(imap).to have_received(:disconnect)
      end

      it "clears the cached state" do
        expect(subject.send(:state)).to be_nil
      end
    end
  end
end
