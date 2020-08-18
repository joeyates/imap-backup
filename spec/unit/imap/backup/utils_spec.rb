describe Imap::Backup::Utils do
  let(:filename) { "foobar" }
  let(:stat) { instance_double(File::Stat, mode: mode) }
  let(:mode) { 0o777 }
  let(:exists) { true }

  before do
    allow(File).to receive(:stat) { stat }
    allow(File).to receive(:exist?).with(filename) { exists }
  end

  describe ".check_permissions" do
    let(:requested) { 0o345 }

    # rubocop:disable RSpec/EmptyExampleGroup
    context "with existing files" do
      [
        [0o100, "less than the limit", true],
        [0o345, "equal to the limit", true],
        [0o777, "over the limit", false]
      ].each do |mode, description, success|
        context "when permissions are #{description}" do
          let(:mode) { mode }

          if success
            it "succeeds" do
              described_class.check_permissions(filename, requested)
            end
          else
            it "fails" do
              message = /Permissions on '.*?' should be .*?, not .*?/
              expect do
                described_class.check_permissions(filename, requested)
              end.to raise_error(RuntimeError, message)
            end
          end
        end
      end
    end
    # rubocop:enable RSpec/EmptyExampleGroup

    context "with non-existent files" do
      let(:exists) { false }
      let(:mode) { 0o111 }

      it "succeeds" do
        described_class.check_permissions(filename, requested)
      end
    end
  end

  describe ".mode" do
    context "with existing files" do
      let(:mode) { 0o2345 }

      it "is the last 9 bits of the file mode" do
        expect(described_class.mode(filename)).to eq(0o345)
      end
    end

    context "with non-existent files" do
      let(:exists) { false }

      it "is nil" do
        expect(described_class.mode(filename)).to be_nil
      end
    end
  end

  describe ".make_folder" do
    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:chmod)
    end

    it "does nothing if an empty path is supplied" do
      expect(FileUtils).to_not receive(:mkdir_p)

      described_class.make_folder("aaa", "", 0o222)
    end

    it "creates the path" do
      expect(FileUtils).to receive(:mkdir_p).with("/base/path/new/folder")

      described_class.make_folder("/base/path", "new/folder", 0o222)
    end

    it "sets permissions on the path" do
      expect(FileUtils).to receive(:chmod).with(0o222, "/base/path/new/folder")

      described_class.make_folder("/base/path/new", "folder", 0o222)
    end
  end
end
