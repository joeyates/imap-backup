require "spec_helper"

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
      subject.run
    end

    context "with messages that are missing" do
      it "restores them" do
        expect(folder).to have_received(:append).with("missing message")
      end

      it "updates the local message id" do
        expect(serializer).to have_received(:update_uid).with(1, 99)
      end
    end

    context "with messages that are present on server" do
      it "does nothing" do
        expect(folder).to_not have_received(:append).with("existing message")
      end
    end
  end
end
