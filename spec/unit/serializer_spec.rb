require "imap/backup/serializer"
require "imap/backup/serializer/imap"
require "imap/backup/serializer/message"
require "imap/backup/serializer/files/path"

module Imap::Backup
  RSpec.describe Serializer do
    subject { described_class.new(files_path: files_path) }

    let(:files) do
      instance_double(
        Serializer::Files, "Files",
        files_path: files_path,
        imap: imap,
        rename: nil,
        reload: nil,
        uid_validity: existing_uid_validity,
        "uid_validity=": nil,
        uids: existing_uids,
        validate!: nil
      )
    end
    let(:imap) { instance_double(Serializer::Imap, "Imap") }
    let(:files_path) do
      instance_double(
        Serializer::Files::Path, "Files::Path",
        base_path: "serializer_path",
        folder_name: folder_name,
        to_s: File.join("serializer_path", folder_name)
      )
    end
    let(:enumerator) { instance_double(Serializer::MessageEnumerator, run: nil) }
    let(:folder_name) { "folder_name" }
    let(:existing_uid_validity) { nil }
    let(:existing_uids) { [1, 2] }
    let(:message) { instance_double(Serializer::Message) }
    let(:directory) { instance_double(Serializer::Directory, ensure_exists: nil) }

    before do
      allow(Serializer::Files).to receive(:new).with(files_path: files_path) { files }
      allow(Serializer::Directory).to receive(:new) { directory }
      allow(Serializer::MessageEnumerator).to receive(:new).with(imap: imap) { enumerator }
    end

    describe "#transaction" do
      it "yields to the supplied block" do
        called = false

        subject.transaction { called = true }

        expect(called).to be true
      end

      it "returns the block's value" do
        result = subject.transaction { :ok }

        expect(result).to eq(:ok)
      end
    end

    describe "#apply_uid_validity" do
      let(:result) { subject.apply_uid_validity("new") }
      let(:action) { -> { result } }

      context "when there is no existing uid_validity" do
        it "sets the metadata file's uid_validity" do
          result

          expect(files).to have_received(:"uid_validity=").with("new")
        end
      end

      context "when the new value is the same as the old value" do
        let(:existing_uid_validity) { "new" }

        it "does nothing" do
          result

          expect(files).to_not have_received(:"uid_validity=")
        end
      end

      context "when the new value is different from the old value" do
        let(:existing_uid_validity) { "existing_uid_validity" }
        let(:unused_name_finder) { instance_double(Serializer::UnusedNameFinder, run: new_folder_path) }
        let(:new_folder_path) { "serializer_path/new_name" }

        before do
          allow(Serializer::UnusedNameFinder).to receive(:new) { unused_name_finder }
        end

        it "renames the existing files" do
          result

          expect(files).to have_received(:rename).with(new_folder_path)
        end

        it "returns the new name for the old folder" do
          expect(result).to eq(new_folder_path)
        end
      end
    end

    describe "#force_uid_validity" do
      let(:action) { -> { subject.force_uid_validity("new") } }

      it "sets the metadata file's uid_validity" do
        subject.force_uid_validity("new")

        expect(files).to have_received(:"uid_validity=").with("new")
      end
    end

    describe "#append" do
      before do
        allow(Serializer::Appender).to receive(:new).with(files: files) { appender }
      end

      let(:action) { -> { subject.append("uid", "message", []) } }
      let(:appender) { instance_double(Serializer::Appender, append: nil) }

      it "runs the Appender" do
        subject.append("uid", "message", [])

        expect(appender).to have_received(:append)
      end
    end

    describe "#filter" do
      let(:appender) { instance_double(Serializer::Appender, append: nil) }
      let(:files) do
        instance_double(
          Serializer::Files, "Old Files",
          delete: nil,
          get: message,
          imap: imap,
          files_path: files_path,
          uid_validity: 1,
          uids: [1]
        )
      end
      let(:files_path) do
        instance_double(
          Serializer::Files::Path, "Files Path",
          base_path: "serializer_path", folder_name: folder_name
        )
      end
      let(:temp_files) do
        instance_double(Serializer::Files, "New Files", "uid_validity=": nil, rename: nil)
      end
      let(:temp_files_path) do
        instance_double(
          Serializer::Files::Path, "Temp Files Path",
          base_path: "serializer_path", folder_name: unused_name
        )
      end
      let(:message) { instance_double(Serializer::Message, uid: 1, body: "body", flags: []) }
      let(:keep) { true }
      let(:unused) { instance_double(Serializer::UnusedNameFinder, run: unused_name) }
      let(:unused_name) { "temp" }

      before do
        allow(Serializer::Appender).to receive(:new) { appender }
        allow(Serializer::UnusedNameFinder).to receive(:new) { unused }
        allow(Serializer::Files).to receive(:new).with(files_path: temp_files_path) { temp_files }
        allow(Serializer::Files::Path).to receive(:new).
          with(base_path: "serializer_path", folder_name: unused_name) { temp_files_path }
        allow(enumerator).to receive(:run).with(uids: [1]).and_yield(message)

        subject.filter { keep }
      end

      it "adds messages" do
        expect(appender).to have_received(:append)
      end

      it "deletes the old files" do
        expect(files).to have_received(:delete)
      end

      it "renames the new files" do
        expect(temp_files).to have_received(:rename).with(files_path)
      end

      context "when the block returns false" do
        let(:keep) { false }

        it "skips the message" do
          expect(appender).to_not have_received(:append)
        end
      end
    end
  end
end
