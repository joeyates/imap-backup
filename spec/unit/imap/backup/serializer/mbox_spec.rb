require "imap/backup/serializer/mbox"

module Imap::Backup
  RSpec.describe Serializer::Mbox do
    subject { described_class.new(folder_path) }

    let(:folder_path) { "folder_path" }
    let(:pathname) { "folder_path.mbox" }
    let(:exists) { true }
    let(:file) { instance_double(File, truncate: nil, write: nil) }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(pathname) { exists }
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(pathname, "ab").and_yield(file)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(pathname) { existing.to_json }
      allow(File).to receive(:stat).and_call_original
      allow(FileUtils).to receive(:rm).and_call_original
      allow(FileUtils).to receive(:rm).with(pathname)
    end

    describe "#valid?" do
      context "when the mailbox exists" do
        it "is true" do
          expect(subject.valid?).to be true
        end
      end

      context "when the mailbox doesn't exist" do
        let(:exists) { false }

        it "is false" do
          expect(subject.valid?).to be false
        end
      end
    end

    describe "#append" do
      it "appends the message" do
        subject.append("message")

        expect(file).to have_received(:write).with("message")
      end
    end

    describe "#delete" do
      context "when the file exists" do
        it "deletes the file" do
          subject.delete

          expect(FileUtils).to have_received(:rm)
        end
      end

      context "when the file does not exist" do
        let(:exists) { false }

        it "does nothing" do
          subject.delete

          expect(FileUtils).to_not have_received(:rm)
        end
      end
    end

    describe "#length" do
      let(:stat) { instance_double(File::Stat, size: 99) }

      before { allow(File).to receive(:stat) { stat } }

      it "returns the length of the mailbox file" do
        expect(subject.length).to eq(99)
      end
    end

    describe "#pathname" do
      it "is the folder_path plus .mbox" do
        expect(subject.pathname).to eq("folder_path.mbox")
      end
    end

    describe "#rename" do
      context "when the mailbox exists" do
        let(:exists) { true }

        before do
          allow(File).to receive(:rename)

          subject.rename("new_name")
        end

        it "renames the mailbox" do
          expect(File).to have_received(:rename)
        end

        it "sets the folder_path" do
          expect(subject.folder_path).to eq("new_name")
        end
      end

      context "when the mailbox doesn't exist" do
        let(:exists) { false }

        it "sets the folder_path" do
          subject.rename("new_name")

          expect(subject.folder_path).to eq("new_name")
        end
      end
    end

    describe "#rollback" do
      let(:stat) { instance_double(File::Stat, size: 123) }

      before do
        allow(File).to receive(:stat) { stat }
        allow(File).to receive(:open).
          with(pathname, File::RDWR | File::CREAT, 0o644).
          and_yield(file)
      end

      it "truncates the mailbox" do
        subject.transaction { subject.rollback }

        expect(file).to have_received(:truncate).with(123)
      end
    end
  end
end
