require "imap/backup/local_only_message_deleter"

module Imap::Backup
  RSpec.describe LocalOnlyMessageDeleter do
    subject { described_class.new(folder, serializer) }

    let(:serializer) { instance_double(Serializer, uids: [1, 2]) }
    let(:folder) { instance_double(Account::Folder, uids: [2]) }
    let(:message_one) { instance_double(Serializer::Message, uid: 1) }
    let(:message_two) { instance_double(Serializer::Message, uid: 2) }
    let(:responses) { [] }

    before do
      allow(serializer).to receive(:filter) do |&block|
        responses << block.call(message_one)
        responses << block.call(message_two)
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
