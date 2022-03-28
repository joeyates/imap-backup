module Imap::Backup
  describe Serializer::MessageEnumerator do
    subject { described_class.new(imap: imap, mbox: mbox) }

    let(:imap) { instance_double(Serializer::Imap) }
    let(:mbox) { instance_double(Serializer::Mbox, pathname: "aaa") }
    let(:enumerator) { instance_double(Serializer::MboxEnumerator) }
    let(:good_uid) { 999 }

    before do
      allow(imap).to receive(:index) { nil }
      allow(imap).to receive(:index).with(good_uid) { 0 }
      allow(Serializer::MboxEnumerator).to receive(:new) { enumerator }
      allow(enumerator).to receive(:each) { ["message"].enum_for(:each) }
    end

    it "yields matching UIDs" do
      expect { |b| subject.run(uids: [good_uid], &b) }.
        to yield_successive_args([good_uid, anything])
    end

    it "yields matching messages" do
      subject.run(uids: [good_uid]) do |_uid, message|
        expect(message.supplied_body).to eq("message")
      end
    end

    context "with UIDs that are not present" do
      it "skips them" do
        expect { |b| subject.run(uids: [good_uid, 1234], &b) }.
          to yield_successive_args([good_uid, anything])
      end
    end
  end
end
