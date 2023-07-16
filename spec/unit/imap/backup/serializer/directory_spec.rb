require "imap/backup/serializer/directory"

module Imap::Backup
  describe Serializer::Directory do
    subject { described_class.new("directory_path", "relative") }

    let(:windows) { false }
    let(:file_mode) { instance_double(FileMode, mode: 0o600) }
    let(:folder_maker) { instance_double(Serializer::FolderMaker, run: nil) }
    let(:exists) { true }

    before do
      allow(File).to receive(:directory?).with(/relative/) { exists }
      allow(Serializer::FolderMaker).to receive(:new) { folder_maker }
      allow(OS).to receive(:windows?) { windows }
      allow(FileMode).to receive(:new) { file_mode }
      allow(FileUtils).to receive(:chmod)
    end

    context "when the directory doesn't exist" do
      let(:exists) { false }

      it "makes the directory" do
        subject.ensure_exists

        expect(folder_maker).to have_received(:run)
      end
    end

    it "sets permissions" do
      subject.ensure_exists

      expect(FileUtils).to have_received(:chmod)
    end

    context "when on Windows" do
      let(:windows) { true }

      it "doesn't set permissions" do
        subject.ensure_exists

        expect(FileUtils).to_not have_received(:chmod)
      end
    end
  end
end
