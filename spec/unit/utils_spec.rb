require "spec_helper"

describe Imap::Backup::Utils do
  let(:filename) { "foobar" }
  let(:stat) { double("File::Stat", mode: mode) }
  let(:mode) { 0777 }
  let(:exists) { true }

  before do
    allow(File).to receive(:stat).and_return(stat)
    allow(File).to receive(:exist?).with(filename).and_return(exists)
  end

  context ".check_permissions" do
    let(:requested) { 0345 }

    context "with existing files" do
      [
        [0100, "less than the limit", true],
        [0345, "equal to the limit", true],
        [0777, "over the limit", false]
      ].each do |mode, description, success|
        context "when permissions are #{description}" do
          let(:mode) { mode }

          if success
            it "succeeds" do
              described_class.check_permissions(filename, requested)
            end
          else
            it "fails" do
              message = format(
                "Permissions on '%s' should be 0%o, not 0%o",
                filename, requested, mode
              )
              expect do
                described_class.check_permissions(filename, requested)
              end.to raise_error(RuntimeError, message)
            end
          end
        end
      end
    end

    context "with non-existent files" do
      let(:exists) { false }
      let(:mode) { 0111 }

      it "succeeds" do
        described_class.check_permissions(filename, requested)
      end
    end
  end

  context ".stat" do
    context "with existing files" do
      let(:mode) { 02345 }

      it "is the last 9 bits of the file mode" do
        expect(described_class.stat(filename)).to eq(0345)
      end
    end

    context "with non-existent files" do
      let(:exists) { false }

      it "is nil" do
        expect(described_class.stat(filename)).to be_nil
      end
    end
  end

  context ".make_folder" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:chmod)
    end

    it "does nothing if an empty path is supplied" do
      described_class.make_folder("aaa", "", 0222)

      expect(FileUtils).to_not have_received(:mkdir_p)
    end

    it "creates the path" do
      described_class.make_folder("/base/path", "new/folder", 0222)

      expect(FileUtils).to have_received(:mkdir_p).with("/base/path/new/folder")
    end

    it "sets permissions on the path" do
      described_class.make_folder("/base/path/new", "folder", 0222)

      expect(FileUtils).
        to have_received(:chmod).with(0222, "/base/path/new/folder")
    end
  end
end
