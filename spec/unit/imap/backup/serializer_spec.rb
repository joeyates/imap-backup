shared_examples "a method that checks for invalid serialization" do
  require "imap/backup/serializer/version2_migrator"

  context "with version 2 metadata files" do
    let(:version2_migrator) do
      instance_double(Imap::Backup::Serializer::Version2Migrator, required?: true, run: false)
    end

    before do
      allow(Imap::Backup::Serializer::Version2Migrator).to receive(:new) { version2_migrator }
      action.call
    end

    it "migrates to version 3" do
      expect(version2_migrator).to have_received(:run)
    end
  end

  context "when either file is invalid" do
    let(:imap_valid) { true }
    let(:mbox_valid) { true }

    before do
      allow(imap).to receive(:valid?) { imap_valid }
      allow(imap).to receive(:delete)
      allow(mbox).to receive(:valid?) { mbox_valid }
      allow(mbox).to receive(:delete)

      action.call
    end

    context "when the imap file is not valid" do
      let(:imap_valid) { false }

      it "deletes the imap file" do
        expect(imap).to have_received(:delete)
      end

      it "deletes the mbox file" do
        expect(mbox).to have_received(:delete)
      end
    end

    context "when the mbox file is not valid" do
      let(:mbox_valid) { false }

      it "deletes the imap file" do
        expect(imap).to have_received(:delete)
      end

      it "deletes the mbox file" do
        expect(mbox).to have_received(:delete)
      end
    end
  end
end

module Imap::Backup
  describe Serializer do
    subject { described_class.new("path", "folder/sub") }

    let(:directory) { instance_double(Serializer::Directory, ensure_exists: nil) }
    let(:imap) do
      instance_double(
        Serializer::Imap,
        valid?: true,
        rename: nil,
        uid_validity: existing_uid_validity,
        "uid_validity=": nil
      )
    end
    let(:mbox) do
      instance_double(
        Serializer::Mbox,
        valid?: true,
        # pathname: "aaa",
        rename: nil,
        touch: nil
      )
    end
    let(:folder_path) { File.expand_path(File.join("path", "folder/sub")) }
    let(:existing_uid_validity) { nil }

    before do
      allow(Serializer::Directory).to receive(:new) { directory }
      allow(Serializer::Imap).to receive(:new).with(folder_path) { imap }
      allow(Serializer::Mbox).to receive(:new) { mbox }
    end

    describe "#apply_uid_validity" do
      it_behaves_like "a method that checks for invalid serialization" do
        let(:action) { -> { result } }
      end

      let(:result) { subject.apply_uid_validity("new") }

      context "when there is no existing uid_validity" do
        it "sets the metadata file's uid_validity" do
          result

          expect(imap).to have_received(:"uid_validity=").with("new")
        end
      end

      context "when the new value is the same as the old value" do
        let(:existing_uid_validity) { "new" }

        it "does nothing" do
          result

          expect(imap).to_not have_received(:"uid_validity=")
        end
      end

      context "when the new value is different from the old value" do
        let(:existing_uid_validity) { "existing" }
        let(:unused_name_finder) { instance_double(Serializer::UnusedNameFinder, run: "new_name") }
        let(:new_folder_path) { File.expand_path(File.join("path/new_name")) }

        before do
          allow(Serializer::UnusedNameFinder).to receive(:new) { unused_name_finder }
        end

        it "renames the existing mailbox" do
          result

          expect(mbox).to have_received(:rename).with(new_folder_path)
        end

        it "renames the existing metadata file" do
          result

          expect(imap).to have_received(:rename).with(new_folder_path)
        end

        it "returns the new name for the old folder" do
          expect(result).to eq("new_name")
        end
      end
    end

    describe "#force_uid_validity" do
      it_behaves_like "a method that checks for invalid serialization" do
        let(:action) { -> { subject.force_uid_validity("new") } }
      end

      it "sets the metadata file's uid_validity" do
        subject.force_uid_validity("new")

        expect(imap).to have_received(:"uid_validity=").with("new")
      end
    end

    describe "#append" do
      it_behaves_like "a method that checks for invalid serialization" do
        let(:action) { -> { subject.append("uid", "message", []) } }
      end

      let(:appender) { instance_double(Serializer::Appender, run: nil) }

      before do
        allow(Serializer::Appender).to receive(:new) { appender }
      end

      it "runs the Appender" do
        subject.append("uid", "message", [])

        expect(appender).to have_received(:run)
      end
    end

    describe "#each_message" do
      it_behaves_like "a method that checks for invalid serialization" do
        let(:action) { -> { subject.each_message([]) {} } }
      end

      let(:message_enumerator) { instance_double(Serializer::MessageEnumerator, run: nil) }

      before do
        allow(Serializer::MessageEnumerator).to receive(:new) { message_enumerator }
      end

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
  end
end
