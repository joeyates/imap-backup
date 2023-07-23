module Imap::Backup
  RSpec.describe Serializer::Appender do
    subject { described_class.new(folder: "appender_path", imap: imap, mbox: mbox) }

    let(:imap) do
      instance_double(Serializer::Imap, uid_validity: existing_uid_validity, rollback: nil)
    end
    let(:mbox) do
      instance_double(Serializer::Mbox, append: nil, rollback: nil)
    end
    let(:existing_uid_validity) { "42" }
    let(:mboxrd_message) do
      instance_double(Email::Mboxrd::Message, to_serialized: "serialized")
    end
    let(:found_message) { nil }
    let(:command) { subject.single(uid: 99, message: "Hi", flags: [:MyFlag]) }

    before do
      allow(imap).to receive(:get) { found_message }
      allow(imap).to receive(:transaction).and_yield
      allow(imap).to receive(:append)
      allow(mbox).to receive(:transaction).and_yield
      allow(Email::Mboxrd::Message).to receive(:new) { mboxrd_message }
    end

    it "appends the message to the mailbox" do
      command

      expect(mbox).to have_received(:append).with("serialized")
    end

    it "appends the UID to the metadata" do
      command

      expect(imap).to have_received(:append).with(99, anything, anything)
    end

    it "appends the message length to the metadata" do
      command

      expect(imap).to have_received(:append).with(anything, "serialized".length, anything)
    end

    it "appends the message flags to the metadata" do
      command

      expect(imap).to have_received(:append).with(anything, anything, flags: [:MyFlag])
    end

    context "when appending to the mailbox causes an error" do
      before do
        allow(mbox).to receive(:append).and_throw(RuntimeError, "Boom")
      end

      it "does not fail" do
        command
      end

      it "leaves the metadata file unchanged" do
        command

        expect(imap).to have_received(:rollback)
      end
    end

    context "when appending to the metadata file causes an error" do
      before do
        allow(imap).to receive(:append).and_throw(RuntimeError, "Boom")
      end

      it "does not fail" do
        command
      end

      it "resets the mailbox to the previous position" do
        command

        expect(mbox).to have_received(:rollback)
      end
    end

    context "when the metadata uid_validity has not been set" do
      let(:existing_uid_validity) { nil }

      it "fails" do
        expect { command }.to raise_error(RuntimeError, /without uid_validity/)
      end
    end

    context "when the message has already been backed up" do
      let(:found_message) { instance_double(Serializer::Message) }

      it "doesn't append to the mailbox file" do
        command

        expect(mbox).to_not have_received(:append)
      end

      it "doesn't append to the metadata file" do
        command

        expect(imap).to_not have_received(:append)
      end
    end
  end
end
