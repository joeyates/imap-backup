describe Imap::Backup::Serializer::MboxStore do
  let(:base_path) { "/base/path" }
  let(:folder) { "the/folder" }
  let(:folder_path) { File.join(base_path, folder) }
  let(:imap_pathname) { folder_path + ".imap" }
  let(:imap_exists) { true }
  let(:imap_file) { double("File - imap", write: nil, close: nil) }
  let(:mbox_pathname) { folder_path + ".mbox" }
  let(:mbox_exists) { true }
  let(:mbox_file) { double("File - mbox", write: nil, close: nil) }
  let(:uids) { [3, 2, 1] }
  let(:imap_content) do
    {
      version: Imap::Backup::Serializer::MboxStore::CURRENT_VERSION,
      uids: uids.sort
    }.to_json
  end

  subject { described_class.new(base_path, folder) }

  before do
    allow(File).to receive(:exist?).with(imap_pathname) { imap_exists }
    allow(File).to receive(:exist?).with(mbox_pathname) { mbox_exists }
    #allow(File).to receive(:exist?).and_call_original

    allow(File).
      to receive(:open).with("/base/path/my/folder.imap") { imap_content }
    allow(File).to receive(:open).with(imap_pathname, "w").and_yield(imap_file)
    allow(File).to receive(:open).with(mbox_pathname, "w").and_yield(mbox_file)
    #allow(File).to receive(:open).and_call_original

    allow(File).to receive(:read).with(imap_pathname) { imap_content }
    #allow(File).to receive(:read).and_call_original

    allow(File).to receive(:unlink).with(imap_pathname)
    allow(File).to receive(:unlink).with(mbox_pathname)
    #allow(File).to receive(:unlink).and_call_original

    allow(FileUtils).to receive(:chmod)
  end

  context "#uids" do
    it "returns the backed-up uids as sorted integers" do
      expect(subject.uids).to eq(uids.map(&:to_i).sort)
    end

    context "when the imap file does not exist" do
      let(:imap_exists) { false }

      it "returns an empty Array" do
        expect(subject.uids).to eq([])
      end
    end

    context "when the mbox does not exist" do
      let(:mbox_exists) { false }

      it "returns an empty Array" do
        expect(subject.uids).to eq([])
      end
    end
  end

  context "#add" do
    let(:mbox_formatted_message) { "message in mbox format" }
    let(:message_uid) { "999" }
    let(:message) do
      double("Email::Mboxrd::Message", to_serialized: mbox_formatted_message)
    end
    let(:updated_imap_content) do
      {
        version: Imap::Backup::Serializer::MboxStore::CURRENT_VERSION,
        uids: (uids + [999]).sort
      }.to_json
    end

    before do
      allow(Email::Mboxrd::Message).to receive(:new).and_return(message)
      allow(File).to receive(:open).with(mbox_pathname, "ab") { mbox_file }
    end

    it "saves the message to the mbox" do
      subject.add(message_uid, "The\nemail\n")

      expect(mbox_file).to have_received(:write).with(mbox_formatted_message)
    end

    it "saves the uid to the imap file" do
      subject.add(message_uid, "The\nemail\n")

      expect(imap_file).to have_received(:write).with(updated_imap_content)
    end

    context "when the message causes parsing errors" do
      before do
        allow(message).to receive(:to_serialized).and_raise(ArgumentError)
      end

      it "skips the message" do
        subject.add(message_uid, "The\nemail\n")
        expect(mbox_file).to_not have_received(:write)
      end

      it "does not fail" do
        expect do
          subject.add(message_uid, "The\nemail\n")
        end.to_not raise_error
      end
    end
  end
end
