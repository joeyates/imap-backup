describe Imap::Backup::Client::Default do
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
end
