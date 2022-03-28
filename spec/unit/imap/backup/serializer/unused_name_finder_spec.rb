module Imap::Backup
  describe Serializer::UnusedNameFinder do
    subject { described_class.new(serializer: serializer) }

    let(:serializer) do
      instance_double(Serializer, folder: "folder", uid_validity: "uid_validity", path: "path")
    end
    let(:imap_test) { instance_double(Serializer::Imap, exist?: imap_test_exists) }
    let(:imap_test_exists) { false }
    let(:new_name) { "folder-uid_validity" }
    let(:test_folder_path) { File.expand_path(File.join("path", new_name)) }
    let(:result) { subject.run }

    before do
      allow(Serializer::Imap).to receive(:new).with(test_folder_path) { imap_test }
    end

    it "returns the folder name with the uid_validity appended" do
      expect(result).to eq(new_name)
    end

    context "when the default rename is not possible" do
      let(:imap_test_exists) { true }
      let(:imap_test1) { instance_double(Serializer::Imap, exist?: false) }
      let(:new_name1) { "folder-uid_validity-1" }
      let(:test_folder_path1) { File.expand_path(File.join("path", new_name1)) }

      before do
        allow(Serializer::Imap).to receive(:new).with(test_folder_path1) { imap_test1 }
      end

      it "appends a numeral" do
        expect(result).to eq(new_name1)
      end
    end
  end
end
