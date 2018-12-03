describe Imap::Backup::Serializer::Mbox do
  let(:base_path) { "/base/path" }
  let(:store) do
    instance_double(
      Imap::Backup::Serializer::MboxStore,
      add: nil,
      uids: nil
    )
  end
  let(:imap_folder) { "folder" }
  let(:permissions) { 0o700 }
  let(:dir_exists) { true }

  before do
    allow(Imap::Backup::Utils).to receive(:make_folder)
    allow(Imap::Backup::Utils).to receive(:mode) { permissions }
    allow(Imap::Backup::Utils).to receive(:check_permissions) { true }
    allow(File).to receive(:directory?) { dir_exists }
  end

  subject { described_class.new(base_path, imap_folder) }

  before do
    allow(FileUtils).to receive(:chmod)
    allow(Imap::Backup::Serializer::MboxStore).to receive(:new) { store }
  end

  context "containing directory" do
    before { subject.uids }

    context "when the IMAP folder has multiple elements" do
      let(:imap_folder) { "folder/path" }

      context "when the containing directory is missing" do
        let(:dir_exists) { false }

        it "is created" do
          expect(Imap::Backup::Utils).to have_received(:make_folder).
            with(base_path, File.dirname(imap_folder), 0o700)
        end
      end
    end

    context "when the containing directory permissons are incorrect" do
      let(:permissions) { 0o777 }

      it "corrects them" do
        path = File.expand_path(File.join(base_path, File.dirname(imap_folder)))
        expect(FileUtils).to have_received(:chmod).with(0o700, path)
      end
    end

    context "when the containing directory permissons are correct" do
      it "does nothing" do
        expect(FileUtils).to_not have_received(:chmod)
      end
    end

    context "when the containing directory exists" do
      it "is not created" do
        expect(Imap::Backup::Utils).to_not have_received(:make_folder).
          with(base_path, File.dirname(imap_folder), 0o700)
      end
    end
  end

  context "#uids" do
    it "calls the store" do
      subject.uids

      expect(store).to have_received(:uids)
    end
  end

  context "#save" do
    it "calls the store" do
      subject.save("foo", "bar")

      expect(store).to have_received(:add)
    end
  end
end
