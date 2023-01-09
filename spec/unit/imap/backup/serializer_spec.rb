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
        save: nil,
        uid_validity: existing_uid_validity,
        "uid_validity=": nil
      )
    end
    let(:mbox) do
      instance_double(
        Serializer::Mbox,
        valid?: true,
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

    describe "#update" do
      let(:flags) { [:Foo] }
      let(:message) { instance_double(Serializer::Message, "flags=": nil) }

      before do
        allow(imap).to receive(:get) { message }

        subject.update(33, flags: flags)
      end

      it "updates the message flags" do
        expect(message).to have_received(:flags=).with(flags)
      end

      it "saves the .imap file" do
        expect(imap).to have_received(:save)
      end

      context "when no flags are supplied" do
        let(:flags) { nil }

        it "does not update the message flags" do
          expect(message).to_not have_received(:flags=)
        end
      end

      context "when the UID is not known" do
        let(:message) { nil }

        it "does not save" do
          expect(imap).to_not have_received(:save)
        end
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

    describe "#filter" do
      let(:appender) { instance_double(Serializer::Appender, run: nil) }
      let(:old_imap) do
        instance_double(
          Serializer::Imap, "Old Imap",
          uid_validity: 1,
          uids: [1],
          get: message,
          delete: nil,
          folder_path: "existing/imap"
        )
      end
      let(:old_mbox) do
        instance_double(
          Serializer::Mbox, "Old Mbox",
          delete: nil,
          folder_path: "existing/mbox"
        )
      end
      let(:imap) { instance_double(Serializer::Imap, "New Imap", "uid_validity=": nil, rename: nil) }
      let(:mbox) { instance_double(Serializer::Mbox, "New Mbox", rename: nil) }
      let(:message) { instance_double(Serializer::Message, uid: 1, body: "body", flags: []) }
      let(:keep) { true }
      let(:unused) { instance_double(Serializer::UnusedNameFinder, run: "temp") }

      before do
        allow(Serializer::Appender).to receive(:new) { appender }
        allow(Serializer::UnusedNameFinder).to receive(:new) { unused }
        allow(Serializer::Imap).to receive(:new).with(/sub$/) { old_imap }
        allow(Serializer::Mbox).to receive(:new).with(/sub$/) { old_mbox }
        allow(Serializer::Imap).to receive(:new).with(/temp$/) { imap }
        allow(Serializer::Mbox).to receive(:new).with(/temp$/) { mbox }
        subject.filter { keep }
      end

      it "adds messages" do
        expect(appender).to have_received(:run)
      end

      it "deletes the old imap" do
        expect(old_imap).to have_received(:delete)
      end

      it "deletes the old mbox" do
        expect(old_mbox).to have_received(:delete)
      end

      it "renames the new imap" do
        expect(imap).to have_received(:rename).with("existing/imap")
      end

      it "renames the new mbox" do
        expect(mbox).to have_received(:rename).with("existing/mbox")
      end

      context "when the block returns false" do
        let(:keep) { false }

        it "skips the message" do
          expect(appender).to_not have_received(:run)
        end
      end
    end
  end
end
