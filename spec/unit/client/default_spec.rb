require "imap/backup/client/default"

require "imap/backup/account"

module Imap::Backup
  RSpec.describe Client::Default do
    subject { described_class.new(account) }

    let(:account) do
      instance_double(
        Account, username: username, server: "imap.example.com", connection_options: {}
      )
    end

    let(:username) { "me@example.com" }
    let(:imap) { instance_double(Net::IMAP, list: imap_folders) }
    let(:imap_folders) { [] }

    before do
      allow(Net::IMAP).to receive(:new) { imap }
    end

    describe "#list" do
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
            instance_double(Net::IMAP::MailboxList, attr: [], name: "INBOX"),
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
            instance_double(Net::IMAP::MailboxList, attr: [], name: "INBOX"),
          ]
        end

        it "filters out NoSelect folders" do
          expect(subject.list).to eq(["Foo", "INBOX"])
        end
      end

      context "when the provider does not respond with its root" do
        before do
          allow(imap).to receive(:list).and_return([])
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
  end
end
