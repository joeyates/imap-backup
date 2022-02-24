describe Imap::Backup::Uploader do
  subject { described_class.new(folder, serializer) }

  let(:folder) do
    instance_double(
      Imap::Backup::Account::Folder, uids: [2, 3], append: 99, name: "foo"
    )
  end
  let(:serializer) do
    instance_double(
      Imap::Backup::Serializer,
      uids: [1, 2],
      update_uid: nil
    )
  end
  let(:missing_message) do
    instance_double(Email::Mboxrd::Message, supplied_body: "missing message")
  end
  let(:existing_message) do
    instance_double(Email::Mboxrd::Message, supplied_body: "existing message")
  end

  def message_enumerator
    yield [1, missing_message]
  end

  describe "#run" do
    before do
      allow(serializer).to receive(:each_message).and_return(enum_for(:message_enumerator))
    end

    context "with messages that are missing" do
      it "restores them" do
        expect(folder).to receive(:append).with(missing_message)

        subject.run
      end

      it "updates the local message id" do
        expect(serializer).to receive(:update_uid).with(1, 99)

        subject.run
      end
    end

    context "with messages that are present on server" do
      it "does nothing" do
        expect(folder).to_not receive(:append).with(existing_message)

        subject.run
      end
    end
  end
end
