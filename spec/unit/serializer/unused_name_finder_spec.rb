require "imap/backup/serializer/unused_name_finder"

module Imap::Backup
  RSpec.describe Serializer::UnusedNameFinder do
    subject { described_class.new(serializer: serializer) }

    let(:serializer) do
      instance_double(
        Serializer,
        folder: "folder",
        uid_validity: 999,
        path: "serializer_path"
      )
    end
    let(:test_serializer) { instance_double(Serializer, validate!: default_serializer_validates) }
    let(:default_serializer_validates) { false }
    let(:new_name) { "folder-#{serializer.uid_validity}" }
    let(:result) { subject.run }
    let(:path) do
      instance_double(Serializer::Files::Path)
    end

    before do
      allow(Serializer::Files::Path).to receive(:new).with(
        base_path: "serializer_path",
        folder_name: new_name
      ) { path }
      allow(Serializer).to receive(:new).with(files_path: path) { test_serializer }
    end

    it "returns the folder name with the uid_validity appended" do
      expect(result).to eq(new_name)
    end

    context "when the default rename is not possible" do
      let(:default_serializer_validates) { true }
      let(:test_serializer1) { instance_double(Serializer, validate!: false) }
      let(:new_name1) { "folder-#{serializer.uid_validity}-1" }
      let(:path1) { instance_double(Serializer::Files::Path, to_s: "foo") }

      before do
        allow(Serializer::Files::Path).to receive(:new).with(
          base_path: "serializer_path",
          folder_name: new_name1
        ) { path1 }
        allow(Serializer).to receive(:new).with(files_path: path1) { test_serializer1 }
      end

      it "appends a numeral" do
        expect(result).to eq(new_name1)
      end
    end
  end
end
