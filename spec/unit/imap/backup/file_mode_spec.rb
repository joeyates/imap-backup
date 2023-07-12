require "imap/backup/file_mode"

module Imap::Backup
  describe FileMode do
    subject { described_class.new(filename: filename) }

    let(:filename) { "filename" }
    let(:exists) { true }
    let(:stat) { instance_double(File::Stat, mode: 0o2345) }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(filename) { exists }
      allow(File).to receive(:stat).with(filename) { stat }
    end

    it "is the last 9 bits of the file mode" do
      expect(subject.mode).to eq(0o345)
    end

    context "with non-existent files" do
      let(:exists) { false }

      it "is nil" do
        expect(subject.mode).to be_nil
      end
    end
  end
end
