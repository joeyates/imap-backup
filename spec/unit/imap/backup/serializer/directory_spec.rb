module Imap::Backup
  describe Serializer::Directory do
    subject { described_class.new("path", "relative") }

    let(:windows) { false }

    before do
      allow(File).to receive(:directory?) { false }
      allow(Utils).to receive(:make_folder)
      allow(OS).to receive(:windows?) { windows }
      allow(Utils).to receive(:mode) { 0600 }
      allow(FileUtils).to receive(:chmod)

      subject.ensure_exists
    end

    describe "#ensure_exists" do
      context "when the directory doesn't exist" do
        it "makes the directory" do
          expect(Utils).to have_received(:make_folder)
        end
      end

      it "sets permissions" do
        expect(FileUtils).to have_received(:chmod)
      end

      context "when on Windows" do
        let(:windows) { true }

        it "doesn't set permissions" do
          expect(FileUtils).to_not have_received(:chmod)
        end
      end
    end
  end
end
