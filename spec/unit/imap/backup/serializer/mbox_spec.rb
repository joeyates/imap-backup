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
      "uid_validity=": nil,
      update_uid: nil
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
    context "when it has multiple elements" do
      let(:imap_folder) { "folder/path" }

      context "when the containing directory is missing" do
        let(:dir_exists) { false }

        it "is created" do
          expect(Imap::Backup::Utils).to receive(:make_folder).
            with(base_path, File.dirname(imap_folder), 0o700)

          subject.uids
        end
      end
    end

    context "when permissions are incorrect" do
      let(:permissions) { 0o777 }

      it "corrects them" do
        path = File.expand_path(File.join(base_path, File.dirname(imap_folder)))
        expect(FileUtils).to receive(:chmod).with(0o700, path)

        subject.uids
      end
    end

    context "when permissons are correct" do
      it "does nothing" do
        expect(FileUtils).to_not receive(:chmod)

        subject.uids
      end
    end

    context "when it exists" do
      it "is not created" do
        expect(Imap::Backup::Utils).to_not receive(:make_folder).
          with(base_path, File.dirname(imap_folder), 0o700)

        subject.uids
      end
    end
  end

  describe "#apply_uid_validity" do
    context "when the existing uid validity is unset" do
      it "sets uid validity" do
        expect(store).to receive(:uid_validity=).with("aaa")

        subject.apply_uid_validity("aaa")
      end

      it "does not rename the store" do
        expect(store).to_not receive(:rename)

        subject.apply_uid_validity("aaa")
      end

      it "returns nil" do
        expect(subject.apply_uid_validity("aaa")).to be_nil
      end
    end

    context "when the uid validity is unchanged" do
      let(:existing_uid_validity) { "aaa" }

      it "does not set uid validity" do
        expect(store).to_not receive(:uid_validity=)

        subject.apply_uid_validity("aaa")
      end

      it "does not rename the store" do
        expect(store).to_not receive(:rename)

        subject.apply_uid_validity("aaa")
      end

      it "returns nil" do
        expect(subject.apply_uid_validity("aaa")).to be_nil
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
      end

      it "sets uid validity" do
        expect(store).to receive(:uid_validity=).with("aaa")

        subject.apply_uid_validity("aaa")
      end

      context "when adding the uid validity does not cause a name clash" do
        it "renames the store, adding the existing uid validity" do
          expect(store).to receive(:rename).with("folder-bbb")

          subject.apply_uid_validity("aaa")
        end

        it "returns the new name" do
          expect(subject.apply_uid_validity("aaa")).to eq("folder-bbb")
        end
      end

      context "when adding the uid validity causes a name clash" do
        let(:exists) { true }

        it "renames the store, adding the existing uid validity and a digit" do
          expect(store).to receive(:rename).with("folder-bbb-1")

          subject.apply_uid_validity("aaa")
        end

        it "returns the new name" do
          expect(subject.apply_uid_validity("aaa")).to eq("folder-bbb-1")
        end
      end
    end
  end

  describe "#force_uid_validity" do
    it "sets the uid_validity" do
      expect(store).to receive(:uid_validity=).with("66")

      subject.force_uid_validity("66")
    end
  end

  describe "#uids" do
    it "calls the store" do
      expect(store).to receive(:uids)

      subject.uids
    end
  end

  describe "#load" do
    before { allow(store).to receive(:load).with("66") { "xxx" } }

    it "returns the value loaded by the store" do
      expect(subject.load("66")).to eq("xxx")
    end
  end

  describe "#each_message" do
    it "calls the store" do
      expect(store).to receive(:each_message).with([1])

      subject.each_message([1])
    end
  end

  describe "#save" do
    it "calls the store" do
      expect(store).to receive(:add).with("foo", "bar")

      subject.save("foo", "bar")
    end
  end

  describe "#rename" do
    it "calls the store" do
      expect(store).to receive(:rename).with("foo")

      subject.rename("foo")
    end

    it "updates the folder name" do
      subject.rename("foo")

      expect(subject.folder).to eq("foo")
    end
  end

  describe "#update_uid" do
    it "calls the store" do
      expect(store).to receive(:update_uid).with("foo", "bar")

      subject.update_uid("foo", "bar")
    end
  end
end
