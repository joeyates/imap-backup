require "imap/backup/serializer/directory_maker"

module Imap::Backup
  RSpec.describe Serializer::DirectoryMaker do
    subject { described_class.new(files_path: files_path) }

    let(:base) { "base" }
    let(:path) { "sub/path" }
    let(:files_path) do
      Serializer::Files::Path.new(base_path: base, folder_name: path)
    end
    let(:directory_path) { File.dirname(files_path.to_s) }
    let(:exists) { false }
    let(:permissions) { 0o700 }
    let(:windows) { false }

    before do
      allow(FileUtils).to receive(:mkdir_p).and_call_original
      allow(FileUtils).to receive(:mkdir_p).with(directory_path)
      allow(FileUtils).to receive(:chmod).and_call_original
      allow(FileUtils).to receive(:chmod).with(permissions, directory_path)
      allow(OS).to receive(:windows?) { windows }
    end

    it "creates the path" do
      subject.run

      expect(FileUtils).to have_received(:mkdir_p).with(directory_path)
    end

    it "sets permissions on the path" do
      subject.run

      expect(FileUtils).to have_received(:chmod).with(permissions, directory_path)
    end

    context "when on Windows" do
      let(:windows) { true }

      it "doesn't set permissions" do
        subject.run

        expect(FileUtils).to_not have_received(:chmod)
      end
    end
  end
end
