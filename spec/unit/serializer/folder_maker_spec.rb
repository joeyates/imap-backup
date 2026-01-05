require "imap/backup/serializer/folder_maker"

module Imap::Backup
  RSpec.describe Serializer::FolderMaker do
    subject { described_class.new(files_path: files_path, permissions: permissions) }

    let(:base) { "base" }
    let(:path) { "sub/path" }
    let(:files_path) do
      Serializer::Files::Path.new(base_path: base, folder_name: path)
    end
    let(:permissions) { 0o222 }
    let(:full_path) { files_path.to_s }
    let(:exists) { false }

    before do
      allow(File).to receive(:stat) { stat }
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(full_path) { exists }
      allow(FileUtils).to receive(:mkdir_p).with(full_path)
      allow(FileUtils).to receive(:chmod).with(permissions, /^base/)
    end

    it "creates the path" do
      subject.run

      expect(FileUtils).to have_received(:mkdir_p).with(full_path)
    end

    it "sets permissions on the path" do
      subject.run

      expect(FileUtils).to have_received(:chmod).with(0o222, "base/sub")
      expect(FileUtils).to have_received(:chmod).with(0o222, full_path)
    end

    context "when an empty path is supplied" do
      let(:path) { "" }

      it "does nothing" do
        subject.run

        expect(FileUtils).to_not have_received(:mkdir_p)
      end
    end
  end
end
