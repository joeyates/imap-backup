module Imap::Backup
  describe Serializer::Version2Migrator do
    subject { described_class.new("path") }

    let(:mailbox_exists) { true }
    let(:mailbox_messages) { ["From me"] }
    let(:metadata_exists) { true }
    let(:metadata) { {version: 2, uids: [33], uid_validity: 123} }
    let(:metadata_content) { metadata.to_json }
    let(:imap) do
      instance_double(Serializer::Imap, append: true, delete: true, "uid_validity=": true)
    end
    let(:file) { instance_double(File) }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("path.mbox") { mailbox_exists }
      allow(File).to receive(:exist?).with("path.imap") { metadata_exists }
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with("path.imap") { metadata_content }
      allow(File).to receive(:open).with("path.mbox", "rb").and_yield(file)
      allow(file).to receive(:gets).and_return(*mailbox_messages, nil)
      allow(Serializer::Imap).to receive(:new) { imap }
    end

    it "deletes the existing metadata" do
      subject.run

      expect(imap).to have_received(:delete)
    end

    it "sets uid_validity" do
      subject.run

      expect(imap).to have_received(:uid_validity=).with(123)
    end

    it "appends the messages" do
      subject.run

      expect(imap).to have_received(:append).with(33, mailbox_messages.first.length)
    end

    it "returns true" do
      expect(subject.run).to be true
    end

    context "when the mailbox file is missing" do
      let(:mailbox_exists) { false }

      it "is false" do
        expect(subject.run).to be false
      end
    end

    context "when the metadata file is missing" do
      let(:metadata_exists) { false }

      it "is false" do
        expect(subject.run).to be false
      end
    end

    context "when the metadata file is not valid JSON" do
      let(:metadata_content) { "{++$$%" }

      it "is false" do
        expect(subject.run).to be false
      end
    end

    context "when the version is not '2'" do
      let(:metadata) { {version: 99, uids: [], uid_validity: 123} }

      it "is false" do
        expect(subject.run).to be false
      end
    end

    context "when the there is no uid_validity" do
      let(:metadata) { {version: 99, uids: []} }

      it "is false" do
        expect(subject.run).to be false
      end
    end

    context "when the there is no Array of UIDs" do
      let(:metadata) { {version: 2, uid_validity: 123} }

      it "is false" do
        expect(subject.run).to be false
      end
    end

    context "when the number of mailbox messages does not match the number of UIDs" do
      let(:mailbox_messages) { ["From me", "From you"] }

      it "is false" do
        expect(subject.run).to be false
      end
    end
  end
end
