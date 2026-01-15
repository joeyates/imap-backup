require "imap/backup/serializer"
require "imap/backup/serializer/delayed_metadata_serializer"

module Imap::Backup
  RSpec.describe Serializer::DelayedMetadataSerializer do
    subject(:delayed_serializer) { described_class.new(serializer: serializer) }

    let(:files_path) { "folder_path" }
    let(:serializer) do
      instance_double(
        Serializer,
        files_path: files_path,
        apply_uid_validity: nil,
        reload: nil
      )
    end
    let(:imap) do
      instance_double(
        Serializer::Imap,
        transaction: nil,
        append: nil,
        update: nil,
        rollback: nil
      )
    end
    let(:mbox) do
      instance_double(
        Serializer::Mbox,
        transaction: nil,
        append: nil
      )
    end
    let(:message_body) { "raw message" }
    let(:serialized_message) { "serialized message" }
    let(:mboxrd_message) do
      instance_double(Email::Mboxrd::Message, to_serialized: serialized_message)
    end
    let(:logger) { instance_double(::Logger, error: nil) }

    before do
      allow(Serializer::Imap).to receive(:new).with(files_path: files_path) { imap }
      allow(Serializer::Mbox).to receive(:new).with(files_path: files_path) { mbox }
      allow(imap).to receive(:transaction).and_yield
      allow(mbox).to receive(:transaction).and_yield
      allow(Email::Mboxrd::Message).to receive(:new) { mboxrd_message }
      allow(Logger).to receive(:logger) { logger }
    end

    describe "#transaction" do
      it "wraps mailbox writes in a mailbox transaction" do
        delayed_serializer.transaction {}

        expect(mbox).to have_received(:transaction)
      end

      it "wraps metadata changes in an imap transaction" do
        delayed_serializer.transaction {}

        expect(imap).to have_received(:transaction)
      end

      it "reloads the serializer when the transaction completes" do
        delayed_serializer.transaction {}

        expect(serializer).to have_received(:reload)
      end

      it "stores appended metadata until commit" do
        delayed_serializer.transaction do
          delayed_serializer.append(123, message_body, [:Seen])
        end

        length = serialized_message.bytesize
        expect(imap).to have_received(:append).with(123, length, flags: [:Seen])
      end

      it "stores metadata updates until commit" do
        delayed_serializer.transaction do
          delayed_serializer.update(55, length: 210, flags: [:Flagged])
        end

        expect(imap).to have_received(:update).with(55, length: 210, flags: [:Flagged])
      end

      it "prevents nested transactions" do
        delayed_serializer.transaction do
          expect do
            delayed_serializer.transaction {}
          end.to raise_error(RuntimeError, /nested transactions/)
        end
      end
    end

    describe "#append" do
      it "serializes messages via Email::Mboxrd" do
        delayed_serializer.transaction do
          delayed_serializer.append(123, message_body, [])
        end

        expect(Email::Mboxrd::Message).to have_received(:new).with(message_body)
      end

      it "writes serialized messages to the mailbox" do
        delayed_serializer.transaction do
          delayed_serializer.append(123, message_body, [])
        end

        expect(mbox).to have_received(:append).with(serialized_message)
      end

      it "requires a surrounding transaction" do
        expect do
          delayed_serializer.append(123, message_body, [])
        end.to raise_error(RuntimeError, /can only be called inside a transaction/)
      end
    end

    describe "#update" do
      it "requires a surrounding transaction" do
        expect do
          delayed_serializer.update(1, length: 10, flags: [])
        end.to raise_error(RuntimeError, /can only be called inside a transaction/)
      end
    end

    describe "#apply_uid_validity" do
      it "delegates to the serializer outside a transaction" do
        delayed_serializer.apply_uid_validity(55)

        expect(serializer).to have_received(:apply_uid_validity).with(55)
      end

      it "fails when called inside a transaction" do
        delayed_serializer.transaction do
          expect do
            delayed_serializer.apply_uid_validity(55)
          end.to raise_error(RuntimeError, /UID validity cannot be changed/)
        end
      end
    end

    describe "commit failures" do
      before do
        allow(imap).to receive(:append).and_raise(RuntimeError, "boom")
      end

      it "rolls back the metadata when committing fails" do
        expect do
          delayed_serializer.transaction do
            delayed_serializer.append(1, message_body, [])
          end
        end.to raise_error(RuntimeError, /boom/)

        expect(imap).to have_received(:rollback)
      end
    end
  end
end
