require "imap/backup/serializer/unused_name_finder"

require "imap/backup/serializer"

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
      instance_double(Serializer::Files::Path, to_s: new_name)
    end

    before do
      allow(Serializer::Files::Path).to receive(:new).
        with(base_path: "serializer_path", folder_name: new_name).
        and_return(path)
      allow(File).to receive(:exist?).with("#{new_name}.imap").and_return(false)
      allow(File).to receive(:exist?).with("#{new_name}.mbox").and_return(false)
    end

    it "returns the folder name with the uid_validity appended" do
      expect(result).to eq(new_name)
    end

    context "when the default rename is not possible" do
      let(:new_name1) { "folder-#{serializer.uid_validity}-1" }
      let(:path1) { instance_double(Serializer::Files::Path, to_s: new_name1) }

      before do
        allow(File).to receive(:exist?).with("#{new_name}.imap").and_return(true)
        allow(Serializer::Files::Path).to receive(:new).
          with(base_path: "serializer_path", folder_name: new_name1).
          and_return(path1)
        allow(File).to receive(:exist?).with("#{new_name1}.imap").and_return(false)
        allow(File).to receive(:exist?).with("#{new_name1}.mbox").and_return(false)
      end

      it "appends a numeral" do
        expect(result).to eq(new_name1)
      end
    end
  end
end
