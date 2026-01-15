require "imap/backup/serializer/unused_name_finder"

require "imap/backup/serializer"

module Imap::Backup
  RSpec.describe Serializer::UnusedNameFinder do
    subject { described_class.new(serializer: serializer) }

    let(:serializer) do
      instance_double(Serializer, uid_validity: uid_validity, files_path: files_path)
    end
    let(:files_path) do
      Serializer::Files::Path.new(base_path: base_path, folder_name: folder)
    end
    let(:uid_validity) { 999 }
    let(:test_serializer) { instance_double(Serializer, validate!: default_serializer_validates) }
    let(:default_serializer_validates) { false }
    let(:base_path) { "serializer_path" }
    let(:folder) { "folder" }
    let(:new_name) { "#{folder}-#{uid_validity}" }
    let(:result) { subject.run }

    before do
      allow(File).to receive(:exist?).with("#{base_path}/#{new_name}.imap") { false }
      allow(File).to receive(:exist?).with("#{base_path}/#{new_name}.mbox") { false }
    end

    it "returns a files path with a folder name with the uid_validity appended" do
      expect(result.folder_name).to eq(new_name)
    end

    context "when the default rename is not possible" do
      let(:new_name1) { "#{folder}-#{uid_validity}-1" }

      before do
        allow(File).to receive(:exist?).with("#{base_path}/#{new_name}.imap") { true }
        allow(File).to receive(:exist?).with("#{base_path}/#{new_name1}.imap") { false }
        allow(File).to receive(:exist?).with("#{base_path}/#{new_name1}.mbox") { false }
      end

      it "appends a numeral" do
        expect(result.folder_name).to eq(new_name1)
      end
    end
  end
end
