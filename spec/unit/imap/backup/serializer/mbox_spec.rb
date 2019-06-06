describe Imap::Backup::Serializer::Mbox do
  subject { described_class.new(base_path, imap_folder) }

  let(:base_path) { "/base/path" }
  let(:store) do
    instance_double(
      Imap::Backup::Serializer::MboxStore,
      add: nil,
      rename: nil,
      uids: nil,
      uid_validity: existing_uid_validity,
      "uid_validity=": nil
    )
  end
  let(:imap_folder) { "folder" }
  let(:permissions) { 0o700 }
  let(:dir_exists) { true }
  let(:existing_uid_validity) { nil }

  before do
    allow(Imap::Backup::Utils).to receive(:make_folder)
    allow(Imap::Backup::Utils).to receive(:mode) { permissions }
    allow(Imap::Backup::Utils).to receive(:check_permissions) { true }
    allow(File).to receive(:directory?) { dir_exists }
    allow(FileUtils).to receive(:chmod)
    allow(Imap::Backup::Serializer::MboxStore).to receive(:new) { store }
  end

  describe "folder path" do
    before { subject.uids }

    context "when it has multiple elements" do
      let(:imap_folder) { "folder/path" }

      context "when the containing directory is missing" do
        let(:dir_exists) { false }

        it "is created" do
          expect(Imap::Backup::Utils).to have_received(:make_folder).
            with(base_path, File.dirname(imap_folder), 0o700)
        end
      end
    end

    context "when permissions are incorrect" do
      let(:permissions) { 0o777 }

      it "corrects them" do
        path = File.expand_path(File.join(base_path, File.dirname(imap_folder)))
        expect(FileUtils).to have_received(:chmod).with(0o700, path)
      end
    end

    context "when permissons are correct" do
      it "does nothing" do
        expect(FileUtils).to_not have_received(:chmod)
      end
    end

    context "when it exists" do
      it "is not created" do
        expect(Imap::Backup::Utils).to_not have_received(:make_folder).
          with(base_path, File.dirname(imap_folder), 0o700)
      end
    end
  end

  describe "#uids" do
    it "calls the store" do
      subject.uids

      expect(store).to have_received(:uids)
    end
  end

  describe "#save" do
    it "calls the store" do
      subject.save("foo", "bar")

      expect(store).to have_received(:add)
    end
  end

  describe "#set_uid_validity" do
    let(:result) { subject.set_uid_validity("aaa") }

    context "when the existing uid validity is unset" do
      let!(:result) { super() }

      it "sets uid validity" do
        expect(store).to have_received(:uid_validity=).with("aaa")
      end

      it "does not rename the store" do
        expect(store).to_not have_received(:rename)
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when the uid validity is unchanged" do
      let!(:result) { super() }
      let(:existing_uid_validity) { "aaa" }

      it "does not set uid validity" do
        expect(store).to_not have_received(:uid_validity=)
      end

      it "does not rename the store" do
        expect(store).to_not have_received(:rename)
      end

      it "returns nil" do
        expect(result).to be_nil
      end
    end

    context "when the uid validity is changed" do
      let(:existing_uid_validity) { "bbb" }
      let(:existing_store) do
        instance_double(Imap::Backup::Serializer::MboxStore)
      end
      let(:exists) { false }

      before do
        allow(Imap::Backup::Serializer::MboxStore).
          to receive(:new).with(anything, /bbb/) { existing_store }
        allow(existing_store).to receive(:exist?).and_return(exists, false)
        result
      end

      it "sets uid validity" do
        expect(store).to have_received(:uid_validity=).with("aaa")
      end

      context "when adding the uid validity does not cause a name clash" do
        it "renames the store, adding the existing uid validity" do
          expect(store).to have_received(:rename).with("folder.bbb")
        end

        it "returns the new name" do
          expect(result).to eq("folder.bbb")
        end
      end

      context "when adding the uid validity causes a name clash" do
        let(:exists) { true }

        it "renames the store, adding the existing uid validity and a digit" do
          expect(store).to have_received(:rename).with("folder.bbb.1")
        end

        it "returns the new name" do
          expect(result).to eq("folder.bbb.1")
        end
      end
    end
  end
end
