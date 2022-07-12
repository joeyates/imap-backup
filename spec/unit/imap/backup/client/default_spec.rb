module Imap::Backup
  describe Client::Default do
    subject { described_class.new("server", {}) }

    let(:imap) { instance_double(Net::IMAP, list: imap_folders) }
    let(:imap_folders) { [] }

    before do
      allow(Net::IMAP).to receive(:new) { imap }
    end

    describe "#list" do
      context "with non-ASCII folder names" do
        let(:imap_folders) do
          [instance_double(Net::IMAP::MailboxList, name: "Gel&APY-scht")]
        end

        it "converts them to UTF-8" do
          expect(subject.list).to eq(["Gelöscht"])
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
