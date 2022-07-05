module Imap::Backup
  describe Serializer::UnusedNameFinder do
    subject { described_class.new(serializer: serializer) }

    let(:serializer) do
      instance_double(Serializer, folder: "folder", uid_validity: "uid_validity", path: "path")
    end
    let(:test_serializer) { instance_double(Serializer, validate!: default_serializer_validates) }
    let(:default_serializer_validates) { false }
    let(:new_name) { "folder-uid_validity" }
    let(:result) { subject.run }

    before do
      allow(Serializer).to receive(:new).with("path", new_name) { test_serializer }
    end

    it "returns the folder name with the uid_validity appended" do
      expect(result).to eq(new_name)
    end

    context "when the default rename is not possible" do
      let(:default_serializer_validates) { true }
      let(:test_serializer1) { instance_double(Serializer, validate!: false) }
      let(:new_name1) { "folder-uid_validity-1" }

      before do
        allow(Serializer).to receive(:new).with("path", new_name1) { test_serializer1 }
      end

      it "appends a numeral" do
        expect(result).to eq(new_name1)
      end
    end
  end
end
