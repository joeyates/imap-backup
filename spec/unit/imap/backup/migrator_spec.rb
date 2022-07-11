require "imap/backup/migrator"

module Imap::Backup
  RSpec.describe Migrator do
    subject { described_class.new(serializer, folder, reset: reset) }

    let(:serializer) { instance_double(Serializer, uids: [1]) }
    let(:folder) do
      instance_double(
        Account::Folder,
        append: nil, clear: nil, create: nil, name: "name", uids: folder_uids
      )
    end
    let(:folder_uids) { [] }
    let(:reset) { false }
    let(:messages) { [[1, message]] }
    let(:message) { instance_double(Email::Mboxrd::Message, supplied_body: body) }
    let(:body) { "body" }

    before do
      allow(serializer).to receive(:each_message) do
        messages.enum_for(:each)
      end
    end

    it "creates the folder" do
      subject.run

      expect(folder).to have_received(:create)
    end

    it "uploads messages" do
      subject.run

      expect(folder).to have_received(:append).with(message)
    end

    context "when the folder is not empty" do
      let(:folder_uids) { [99] }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(RuntimeError, /The destination folder 'name' is not empty/)
      end

      context "when `reset` is true" do
        let(:reset) { true }

        it "clears the folder" do
          subject.run

          expect(folder).to have_received(:clear)
        end
      end
    end

    context "when the upload fails" do
      before do
        allow(folder).to receive(:append).and_raise(RuntimeError)
      end

      it "continues to work" do
        subject.run
      end
    end
  end
end
