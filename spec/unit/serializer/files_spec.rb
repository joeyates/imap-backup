require "imap/backup/serializer/directory_maker"
require "imap/backup/serializer/files"
require "imap/backup/serializer/message"
require "imap/backup/serializer/message_enumerator"

module Imap::Backup
  RSpec.shared_examples "a method that checks for invalid serialization" do
    context "when either file is invalid" do
      let(:imap_valid) { true }
      let(:mbox_valid) { true }

      before do
        allow(imap).to receive(:pathname) { "imap pathname" }
        allow(imap).to receive(:valid?) { imap_valid }
        allow(imap).to receive(:exist?) { true }
        allow(imap).to receive(:delete)
        allow(mbox).to receive(:pathname) { "mbox pathname" }
        allow(mbox).to receive(:valid?) { mbox_valid }
        allow(mbox).to receive(:exist?) { true }
        allow(mbox).to receive(:delete)

        action.call
      end

      context "when the imap file is not valid" do
        let(:imap_valid) { false }

        it "deletes the imap file" do
          expect(imap).to have_received(:delete).at_least(:once)
        end

        it "deletes the mbox file" do
          expect(mbox).to have_received(:delete).at_least(:once)
        end
      end

      context "when the mbox file is not valid" do
        let(:mbox_valid) { false }

        it "deletes the imap file" do
          expect(imap).to have_received(:delete).at_least(:once)
        end

        it "deletes the mbox file" do
          expect(mbox).to have_received(:delete).at_least(:once)
        end
      end
    end
  end

  RSpec.shared_examples "a method sets up the folder directory" do
    it "ensures the folder's containing directory exists" do
      action.call

      expect(directory_maker).to have_received(:run).at_least(:once)
    end

    context "when the directory contains invalid characters" do
      let(:folder_name) { "a:b/sub" }
      let(:sanitized_name) { "a%3a;b/sub" }
      let(:sanitized_files_path) do
        instance_double(
          Serializer::Files::Path,
          "sanitized Files::Path",
          base_path: "serializer_path",
          folder_name: sanitized_name,
          to_s: File.join("serializer_path", sanitized_name)
        )
      end

      before do
        allow(Serializer::Files::Path).to receive(:new).with(
          base_path: "serializer_path", folder_name: sanitized_name
        ) { sanitized_files_path }
      end

      it "creates it using valid characters" do
        action.call

        expect(Serializer::DirectoryMaker).
          to have_received(:new).
          with(files_path: sanitized_files_path).
          at_least(:once)
      end
    end
  end

  RSpec.shared_examples "a method that sanitizes folder paths" do
    let(:folder_name) { "a:b/%;::" }
    let(:sanitized_name) { "a%3a;b/%25;%3b;%3a;%3a;" }
    let(:sanitized_files_path) do
      instance_double(
        Serializer::Files::Path,
        "sanitized Files::Path",
        base_path: "serializer_path",
        folder_name: sanitized_name
      )
    end

    before do
      allow(Serializer::Files::Path).to receive(:new).with(
        base_path: "serializer_path", folder_name: sanitized_name
      ) { sanitized_files_path }
    end

    it "sanitizes the .imap path" do
      expect(Serializer::Imap).to receive(:new).with(
        files_path: sanitized_files_path
      )

      action.call
    end

    it "sanitizes the .mbox path" do
      action.call

      expect(Serializer::Mbox).to have_received(:new).with(files_path: sanitized_files_path)
    end
  end

  RSpec.describe Serializer::Files, :silence_logging do
    subject { described_class.new(files_path: files_path) }

    let(:files_path) do
      instance_double(
        Serializer::Files::Path, "Supplied",
        base_path: "serializer_path",
        folder_name: folder_name
      )
    end
    let(:sanitized_files_path) do
      instance_double(
        Serializer::Files::Path, "Sanitized",
        base_path: "serializer_path",
        folder_name: sanitized_name
      )
    end
    let(:directory_maker) { instance_double(Serializer::DirectoryMaker, run: true) }
    let(:imap) { instance_double(Serializer::Imap, valid?: true) }
    let(:mbox) { instance_double(Serializer::Mbox, valid?: true) }
    let(:folder_name) { "INBOX/sub:folder" }
    let(:sanitized_name) { "INBOX/sub%3a;folder" }

    before do
      allow(Serializer::Files::Path).to receive(:new).with(
        base_path: "serializer_path", folder_name: sanitized_name
      ) { sanitized_files_path }
      allow(Serializer::DirectoryMaker).to receive(:new).with(
        files_path: sanitized_files_path
      ) { directory_maker }
      allow(Serializer::Imap).to receive(:new) { imap }
      allow(Serializer::Mbox).to receive(:new) { mbox }
    end

    describe "#check_integrity!" do
      let(:checker) { instance_double(Serializer::IntegrityChecker, run: nil) }
      let(:action) { -> { subject.check_integrity! } }

      before do
        allow(Serializer::IntegrityChecker).to receive(:new) { checker }
      end

      it_behaves_like "a method sets up the folder directory"
      it_behaves_like "a method that sanitizes folder paths"

      it "runs the checker" do
        subject.check_integrity!

        expect(checker).to have_received(:run)
      end

      it "returns nil" do
        expect(subject.check_integrity!).to be_nil
      end
    end

    describe "#delete" do
      let(:action) { -> { subject.delete } }

      before do
        allow(imap).to receive(:delete)
        allow(mbox).to receive(:delete)
      end

      it_behaves_like "a method that checks for invalid serialization"
      it_behaves_like "a method sets up the folder directory"
      it_behaves_like "a method that sanitizes folder paths"

      it "deletes the imap file" do
        subject.delete

        expect(imap).to have_received(:delete)
      end

      it "deletes the mbox file" do
        subject.delete

        expect(mbox).to have_received(:delete)
      end

      it "reloads the serializer" do
        subject.imap
        subject.delete
        subject.imap

        expect(Serializer::Imap).to have_received(:new).twice
      end

      it "reloads the mbox" do
        subject.mbox
        subject.delete
        subject.mbox

        expect(Serializer::Mbox).to have_received(:new).twice
      end
    end

    describe "#each_message" do
      before do
        allow(Serializer::MessageEnumerator).to receive(:new) { message_enumerator }
      end

      let(:action) { -> { subject.each_message([]) {} } }
      let(:message_enumerator) { instance_double(Serializer::MessageEnumerator, run: nil) }

      it_behaves_like "a method that checks for invalid serialization"
      it_behaves_like "a method sets up the folder directory"

      it "runs the MessageEnumerator" do
        subject.each_message([]) {}

        expect(message_enumerator).to have_received(:run)
      end

      context "when called without a block" do
        it "returns an Enumerator" do
          expect(subject.each_message([])).to be_a(Enumerator)
        end
      end
    end

    describe "#get" do
      let(:action) { -> { subject.get(123) } }
      let(:message) { instance_double(Serializer::Message, uid: 1, body: "body", flags: []) }

      before do
        allow(imap).to receive(:get) { message }
      end

      it_behaves_like "a method that checks for invalid serialization"
      it_behaves_like "a method sets up the folder directory"
      it_behaves_like "a method that sanitizes folder paths"

      it "returns the message metadata" do
        expect(subject.get(123)).to eq(message)
      end
    end

    describe "#messages" do
      let(:action) { -> { subject.messages } }
      let(:metadata_messages) { [{uid: 1}] }

      before do
        allow(imap).to receive(:messages) { metadata_messages }
      end

      it_behaves_like "a method that checks for invalid serialization"
      it_behaves_like "a method sets up the folder directory"
      it_behaves_like "a method that sanitizes folder paths"

      it "returns the messages" do
        expect(subject.messages).to eq(metadata_messages)
      end
    end

    describe "#uid_validity" do
      let(:existing_uid_validity) { 17 }
      let(:action) { -> { subject.uid_validity } }

      before do
        allow(imap).to receive(:uid_validity) { existing_uid_validity }
      end

      it_behaves_like "a method that checks for invalid serialization"
      it_behaves_like "a method sets up the folder directory"
      it_behaves_like "a method that sanitizes folder paths"

      it "returns the uid_validity" do
        expect(subject.uid_validity).to eq(existing_uid_validity)
      end
    end

    describe "#uid_validity=" do
      let(:new_uid_validity) { 42 }
      let(:action) { -> { subject.uid_validity = new_uid_validity } }

      before do
        allow(imap).to receive(:"uid_validity=")
        allow(mbox).to receive(:touch)
      end

      it_behaves_like "a method that checks for invalid serialization"
      it_behaves_like "a method sets up the folder directory"
      it_behaves_like "a method that sanitizes folder paths"

      it "sets the uid_validity" do
        subject.uid_validity = new_uid_validity

        expect(imap).to have_received(:"uid_validity=").with(new_uid_validity)
      end

      it "touches the mbox file" do
        subject.uid_validity = new_uid_validity

        expect(mbox).to have_received(:touch)
      end
    end

    describe "#uids" do
      let(:action) { -> { subject.uids } }
      let(:existing_uids) { [1, 2] }

      before do
        allow(imap).to receive(:uids) { existing_uids }
      end

      it_behaves_like "a method that checks for invalid serialization"
      it_behaves_like "a method sets up the folder directory"
      it_behaves_like "a method that sanitizes folder paths"

      it "returns the uids" do
        expect(subject.uids).to eq(existing_uids)
      end
    end

    describe "#update_uid" do
      let(:action) { -> { subject.update_uid(10, 11) } }

      before do
        allow(imap).to receive(:update_uid)
      end

      it_behaves_like "a method that checks for invalid serialization"
      it_behaves_like "a method sets up the folder directory"
      it_behaves_like "a method that sanitizes folder paths"

      it "updates the message metadata" do
        subject.update_uid(10, 11)

        expect(imap).to have_received(:update_uid).with(10, 11)
      end
    end

    describe "#update" do
      let(:flags) { [:Foo] }

      before do
        allow(imap).to receive(:update)

        subject.update(33, flags: flags)
      end

      it "updates the .imap file" do
        expect(imap).to have_received(:update).with(33, flags: flags)
      end
    end

    describe "#validate!" do
      it "returns true" do
        expect(subject.validate!).to be true
      end

      context "when called repeatedly" do
        it "returns true" do
          subject.validate!

          expect(subject.validate!).to be true
        end
      end
    end
  end
end
