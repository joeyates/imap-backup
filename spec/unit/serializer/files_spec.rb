require "imap/backup/serializer/files"

module Imap::Backup
  RSpec.describe Serializer::Files do
    subject { described_class.new(path: "/path/to/backup", folder: "INBOX") }

    let(:directory) { instance_double(Serializer::Directory, ensure_exists: true) }
    let(:imap) { instance_double(Serializer::Imap, valid?: true) }
    let(:mbox) { instance_double(Serializer::Mbox, valid?: true) }

    before do
      allow(Serializer::Directory).to receive(:new) { directory}
      allow(Serializer::Imap).to receive(:new) { imap }
      allow(Serializer::Mbox).to receive(:new) { mbox }
    end

    describe "#validate!" do
      it "returns true" do
        expect(subject.validate!).to be true
      end

      context "when called repeatedly" do
        it "returns true" do
          subject.validate!

          expect(subject.validate!).to be true
        end
      end
    end

    describe "#check_integrity!" do
      let(:checker) { instance_double(Serializer::IntegrityChecker, run: nil) }

      before do
        allow(Serializer::IntegrityChecker).to receive(:new) { checker }
      end

      it "runs the checker" do
        subject.check_integrity!

        expect(checker).to have_received(:run)
      end

      it "returns nil" do
        expect(subject.check_integrity!).to be_nil
      end
    end
  end
end