describe Imap::Backup::Serializer::MboxStore do
  subject { described_class.new(base_path, folder) }

  let(:base_path) { "/base/path" }
  let(:folder) { "the/folder" }
  let(:folder_path) { File.join(base_path, folder) }
  let(:imap_pathname) { folder_path + ".imap" }
  let(:imap_exists) { true }
  let(:imap_file) { instance_double(File, write: nil, close: nil) }
  let(:mbox_pathname) { folder_path + ".mbox" }
  let(:mbox_exists) { true }
  let(:mbox_file) { instance_double(File, write: nil, close: nil) }
  let(:uids) { [3, 2, 1] }
  let(:imap_content) do
    {
      version: Imap::Backup::Serializer::MboxStore::CURRENT_VERSION,
      uid_validity: uid_validity,
      uids: uids
    }.to_json
  end
  let(:uid_validity) { 123 }

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(imap_pathname) { imap_exists }
    allow(File).to receive(:exist?).with(mbox_pathname) { mbox_exists }

    allow(File).to receive(:open).and_call_original
    allow(File).
      to receive(:open).with("/base/path/my/folder.imap") { imap_content }
    allow(File).to receive(:open).with(imap_pathname, "w").and_yield(imap_file)
    allow(File).to receive(:open).with(mbox_pathname, "w").and_yield(mbox_file)

    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(imap_pathname) { imap_content }

    allow(File).to receive(:unlink).and_call_original
    allow(File).to receive(:unlink).with(imap_pathname)
    allow(File).to receive(:unlink).with(mbox_pathname)

    allow(FileUtils).to receive(:chmod)
  end

  describe "#uid_validity=" do
    let(:new_uid_validity) { "13" }
    let(:updated_imap_content) do
      {
        version: Imap::Backup::Serializer::MboxStore::CURRENT_VERSION,
        uid_validity: new_uid_validity,
        uids: uids
      }.to_json
    end

    it "sets uid_validity" do
      subject.uid_validity = new_uid_validity

      expect(subject.uid_validity).to eq(new_uid_validity)
    end

    it "writes the imap file" do
      expect(imap_file).to receive(:write).with(updated_imap_content)

      subject.uid_validity = new_uid_validity
    end
  end

  describe "#uids" do
    it "returns the backed-up uids as integers" do
      expect(subject.uids).to eq(uids.map(&:to_i))
    end

    context "when the imap file does not exist" do
      let(:imap_exists) { false }

      it "returns an empty Array" do
        expect(subject.uids).to eq([])
      end
    end

    context "when the imap file is malformed" do
      before do
        allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      end

      it "returns an empty Array" do
        expect(subject.uids).to eq([])
      end

      it "deletes the imap file" do
        expect(File).to receive(:unlink).with(imap_pathname)

        subject.uids
      end

      it "deletes the mbox file" do
        expect(File).to receive(:unlink).with(mbox_pathname)

        subject.uids
      end

      it "writes a blank mbox file" do
        expect(mbox_file).to receive(:write).with("")

        subject.uids
      end
    end

    context "when the mbox does not exist" do
      let(:mbox_exists) { false }

      it "returns an empty Array" do
        expect(subject.uids).to eq([])
      end
    end
  end

  describe "#add" do
    let(:mbox_formatted_message) { "message in mbox format" }
    let(:message_uid) { "999" }
    let(:message) do
      instance_double(
        Email::Mboxrd::Message,
        to_serialized: mbox_formatted_message
      )
    end
    let(:updated_imap_content) do
      {
        version: Imap::Backup::Serializer::MboxStore::CURRENT_VERSION,
        uid_validity: uid_validity,
        uids: uids + [999]
      }.to_json
    end

    before do
      allow(Email::Mboxrd::Message).to receive(:new) { message }
      allow(File).to receive(:open).with(mbox_pathname, "ab") { mbox_file }
    end

    it "saves the message to the mbox" do
      expect(mbox_file).to receive(:write).with(mbox_formatted_message)

      subject.add(message_uid, "The\nemail\n")
    end

    it "saves the uid to the imap file" do
      expect(imap_file).to receive(:write).with(updated_imap_content)

      subject.add(message_uid, "The\nemail\n")
    end

    context "when the message is already downloaded" do
      let(:uids) { [999] }

      it "skips the message" do
        expect(mbox_file).to_not receive(:write)

        subject.add(message_uid, "The\nemail\n")
      end
    end

    context "when the message causes parsing errors" do
      before do
        allow(message).to receive(:to_serialized).and_raise(ArgumentError)
      end

      it "skips the message" do
        expect(mbox_file).to_not receive(:write)

        subject.add(message_uid, "The\nemail\n")
      end

      it "does not fail" do
        expect do
          subject.add(message_uid, "The\nemail\n")
        end.to_not raise_error
      end
    end
  end

  describe "#load" do
    let(:uid) { "1" }
    let(:enumerator) do
      instance_double(Imap::Backup::Serializer::MboxEnumerator)
    end
    let(:enumeration) { instance_double(Enumerator) }

    before do
      allow(Imap::Backup::Serializer::MboxEnumerator).
        to receive(:new) { enumerator }
      allow(enumerator).to receive(:each) { enumeration }
      allow(enumeration).
        to receive(:with_index).
        and_yield("", 0).
        and_yield("", 1).
        and_yield("ciao", 2)
    end

    it "returns the message" do
      expect(subject.load(uid).supplied_body).to eq("ciao")
    end

    context "when the UID is unknown" do
      let(:uid) { "99" }

      it "returns nil" do
        expect(subject.load(uid)).to be_nil
      end
    end
  end

  describe "#update_uid" do
    let(:old_uid) { "2" }
    let(:updated_imap_content) do
      {
        version: Imap::Backup::Serializer::MboxStore::CURRENT_VERSION,
        uid_validity: uid_validity,
        uids: [3, 999, 1]
      }.to_json
    end

    it "updates the stored UID" do
      expect(imap_file).to receive(:write).with(updated_imap_content)

      subject.update_uid(old_uid, "999")
    end

    context "when the UID is unknown" do
      let(:old_uid) { "42" }

      it "does nothing" do
        expect(imap_file).to_not receive(:write)

        subject.update_uid(old_uid, "999")
      end
    end
  end

  describe "#reset" do
    it "deletes the imap file" do
      expect(File).to receive(:unlink).with(imap_pathname)

      subject.reset
    end

    it "deletes the mbox file" do
      expect(File).to receive(:unlink).with(mbox_pathname)

      subject.reset
    end

    it "writes a blank mbox file" do
      expect(mbox_file).to receive(:write).with("")

      subject.reset
    end
  end

  describe "#rename" do
    let(:new_name) { "new_name" }
    let(:new_folder_path) { File.join(base_path, new_name) }
    let(:new_imap_name) { new_folder_path + ".imap" }
    let(:new_mbox_name) { new_folder_path + ".mbox" }

    before do
      allow(File).to receive(:rename).and_call_original
      allow(File).to receive(:rename).with(imap_pathname, new_imap_name)
      allow(File).to receive(:rename).with(mbox_pathname, new_mbox_name)
    end

    it "renames the imap file" do
      expect(File).to receive(:rename).with(imap_pathname, new_imap_name)

      subject.rename(new_name)
    end

    it "renames the mbox file" do
      expect(File).to receive(:rename).with(mbox_pathname, new_mbox_name)

      subject.rename(new_name)
    end

    it "updates the folder name" do
      subject.rename(new_name)

      expect(subject.folder).to eq(new_name)
    end
  end
end
