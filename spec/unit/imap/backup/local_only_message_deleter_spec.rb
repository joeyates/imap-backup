module Imap::Backup
  describe LocalOnlyMessageDeleter do
    subject { described_class.new(folder, serializer) }

    let(:serializer) { instance_double(Serializer, uids: [1, 2]) }
    let(:folder) { instance_double(Account::Folder, uids: [2]) }
    let(:message1) { instance_double(Serializer::Message, uid: 1) }
    let(:message2) { instance_double(Serializer::Message, uid: 2) }
    let(:responses) { [] }

    before do
      allow(serializer).to receive(:filter) do |&block|
        responses << block.call(message1)
        responses << block.call(message2)
      end
    end

    context "with UIDs only present on the local backup" do
      it "indicates not to keep the message" do
        subject.run

        expect(responses.first).to be false
      end
    end

    context "with UIDs present locally and on the server" do
      it "indicates to keep the message" do
        subject.run

        expect(responses.last).to be true
      end
    end
  end
end
