require "imap/backup/serializer/integrity_checker"

module Imap::Backup
  RSpec.describe Serializer::IntegrityChecker do
    subject { described_class.new(imap: imap, mbox: mbox) }

    let(:imap) do
      instance_double(Serializer::Imap, valid?: imap_valid, messages: messages, pathname: "imap")
    end
    let(:imap_valid) { true }
    let(:messages) { [message1] }
    let(:message1) do
      instance_double(Serializer::Message, offset: 0, length: body1.length, uid: "uid")
    end
    let(:mbox) do
      instance_double(
        Serializer::Mbox, exist?: mbox_exists, length: mbox_length, read: body1, pathname: "mbox"
      )
    end
    let(:mbox_exists) { true }
    let(:mbox_length) { body1.length }
    let(:body1) { "From #{'a' * 95}" }

    it "returns nil" do
      expect(subject.run).to be nil
    end

    context "when the folder is empty" do
      let(:messages) { [] }
      let(:body1) { "" }

      it "returns nil" do
        expect(subject.run).to be nil
      end

      context "when the mbox is not empty" do
        let(:body1) { "Foo" }

        it "fails" do
          expect do
            subject.run
          end.to raise_error(Serializer::FolderIntegrityError, /not empty/)
        end
      end
    end

    context "when the imap offsets are out of order" do
      let(:messages) { [message2, message1] }
      let(:message2) { instance_double(Serializer::Message, offset: body1.length, length: 99) }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(Serializer::FolderIntegrityError, /out of order/)
      end
    end

    context "when the mbox is shorter than expected" do
      let(:mbox_length) { body1.length - 1 }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(Serializer::FolderIntegrityError, /shorter than indicated/)
      end
    end

    context "when the mbox is longer than expected" do
      let(:mbox_length) { body1.length + 1 }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(Serializer::FolderIntegrityError, /longer than indicated/)
      end
    end

    context "when messages do not start at the indicated offsets" do
      before do
        allow(mbox).to receive(:read) { "Wrong text" }
      end

      it "fails" do
        expect do
          subject.run
        end.to raise_error(Serializer::FolderIntegrityError, /not found/)
      end
    end
  end
end
