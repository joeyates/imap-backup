require "imap/backup/local_only_message_deleter"

require "imap/backup/account/folder"
require "imap/backup/serializer"
require "imap/backup/serializer/message"

module Imap::Backup
  RSpec.describe LocalOnlyMessageDeleter do
    subject { described_class.new(folder, serializer) }

    let(:serializer) { instance_double(Serializer, uids: [1, 2]) }
    let(:folder) { instance_double(Account::Folder, uids: [2]) }
    let(:message_one) { instance_double(Serializer::Message, uid: 1) }
    let(:message_two) { instance_double(Serializer::Message, uid: 2) }
    let(:responses) { [] }
    let(:logger) { instance_double(::Logger, info: nil, debug: nil) }

    before do
      allow(Logger).to receive(:logger) { logger }
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

      it "logs the removal" do
        subject.run

        expect(logger).to have_received(:info).
          with("Deleting messages only present locally")
      end
    end

    context "with UIDs present locally and on the server" do
      it "indicates to keep the message" do
        subject.run

        expect(responses.last).to be true
      end
    end

    context "when there are no local-only messages" do
      let(:folder) { instance_double(Account::Folder, uids: [1, 2]) }

      it "returns without filtering" do
        subject.run

        expect(serializer).to_not have_received(:filter)
      end

      it "logs that nothing will be deleted" do
        subject.run

        expect(logger).to have_received(:debug).
          with("There are no 'local-only' messages to delete")
      end
    end
  end
end
