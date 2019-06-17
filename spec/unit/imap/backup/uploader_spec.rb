describe Imap::Backup::Uploader do
  subject { described_class.new(folder, serializer) }

  let(:folder) do
    instance_double(Imap::Backup::Account::Folder, uids: [2, 3], append: 99)
  end
  let(:serializer) do
    instance_double(
      Imap::Backup::Serializer::Mbox,
      uids: [1, 2],
      update_uid: nil
    )
  end

  describe "#run" do
    before do
      allow(serializer).to receive(:load).with(1) { "missing message" }
      allow(serializer).to receive(:load).with(2) { "existing message" }
    end

    context "with messages that are missing" do
      it "restores them" do
        expect(folder).to receive(:append).with("missing message")

        subject.run
      end

      it "updates the local message id" do
        expect(serializer).to receive(:update_uid).with(1, 99)

        subject.run
      end
    end

    context "with messages that are present on server" do
      it "does nothing" do
        expect(folder).to_not receive(:append).with("existing message")

        subject.run
      end
    end
  end
end
