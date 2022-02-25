module Imap::Backup
  describe Serializer do
    subject { described_class.new("path", "folder/sub") }

    let(:directory) { instance_double(Serializer::Directory, ensure_exists: nil) }
    let(:imap) do
      instance_double(
        Serializer::Imap,
        exist?: true,
        rename: nil,
        uid_validity: existing_uid_validity,
        "uid_validity=": nil
      )
    end
    let(:mbox) do
      instance_double(
        Serializer::Mbox,
        append: nil,
        exist?: false,
        length: 1,
        pathname: "aaa",
        rename: nil,
        rewind: nil
      )
    end
    let(:folder_path) { File.expand_path(File.join("path", "folder/sub")) }
    let(:existing_uid_validity) { nil }
    let(:enumerator) { instance_double(Serializer::MboxEnumerator) }

    before do
      allow(Serializer::Directory).to receive(:new) { directory }
      allow(Serializer::Imap).to receive(:new).with(folder_path) { imap }
      allow(Serializer::Mbox).to receive(:new) { mbox }
      allow(Serializer::MboxEnumerator).to receive(:new) { enumerator }
    end

    describe "#apply_uid_validity" do
      let(:imap_test) { instance_double(Serializer::Imap, exist?: imap_test_exists) }
      let(:imap_test_exists) { false }
      let(:test_folder_path) do
        File.expand_path(File.join("path", "folder/sub-#{existing_uid_validity}"))
      end
      let(:result) { subject.apply_uid_validity("new") }

      before do
        allow(Serializer::Imap).to receive(:new).with(test_folder_path) { imap_test }
      end

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

        it "renames the existing mailbox" do
          result

          expect(mbox).to have_received(:rename).with(test_folder_path)
        end

        it "renames the existing metadata file" do
          result

          expect(imap).to have_received(:rename).with(test_folder_path)
        end

        it "returns the new name for the old folder" do
          expect(result).to eq("folder/sub-existing")
        end

        context "when the default rename is not possible" do
          let(:imap_test_exists) { true }
          let(:imap_test1) { instance_double(Serializer::Imap, exist?: false) }
          let(:test_folder_path1) do
            File.expand_path(File.join("path", "folder/sub-#{existing_uid_validity}-1"))
          end

          before do
            allow(Serializer::Imap).to receive(:new).with(test_folder_path1) { imap_test1 }
          end

          it "renames the mailbox, appending a numeral" do
            result

            expect(mbox).to have_received(:rename).with(test_folder_path1)
          end

          it "renames the metadata file, appending a numeral" do
            result

            expect(imap).to have_received(:rename).with(test_folder_path1)
          end
        end
      end
    end

    describe "#force_uid_validity" do
      it "sets the metadata file's uid_validity" do
        subject.force_uid_validity("new")

        expect(imap).to have_received(:"uid_validity=").with("new")
      end
    end

    describe "#append" do
      let(:existing_uid_validity) { "42" }
      let(:mboxrd_message) do
        instance_double(Email::Mboxrd::Message, to_serialized: "serialized")
      end
      let(:uid_found) { false }
      let(:command) { subject.append(99, "Hi") }

      before do
        allow(imap).to receive(:include?) { uid_found }
        allow(imap).to receive(:append)
        allow(Email::Mboxrd::Message).to receive(:new) { mboxrd_message }
      end

      it "appends the message to the mailbox" do
        command

        expect(mbox).to have_received(:append).with("serialized")
      end

      it "appends the UID to the metadata" do
        command

        expect(imap).to have_received(:append).with(99)
      end

      context "when appending to the mailbox causes an error" do
        before do
          allow(mbox).to receive(:append).and_throw(RuntimeError, "Boom")
        end

        it "does not fail" do
          command
        end

        it "leaves the metadata file unchanged" do
          command

          expect(imap).to_not have_received(:append)
        end
      end

      context "when appending to the metadata file causes an error" do
        before do
          allow(imap).to receive(:append).and_throw(RuntimeError, "Boom")
        end

        it "does not fail" do
          command
        end

        it "reset the mailbox to the previous position" do
          command

          expect(mbox).to have_received(:rewind)
        end
      end

      context "when the metadata uid_validity has not been set" do
        let(:existing_uid_validity) { nil }

        it "fails" do
          expect { command }.to raise_error(RuntimeError, /without uid_validity/)
        end
      end

      context "when the message has already been backed up" do
        let(:uid_found) { true }

        it "doesn't append to the mailbox file" do
          command

          expect(mbox).to_not have_received(:append)
        end

        it "doesn't append to the metadata file" do
          command

          expect(imap).to_not have_received(:append)
        end
      end
    end

    describe "#load" do
      let(:uid) { 999 }
      let(:imap_index) { 0 }
      let(:result) { subject.load(uid) }

      before do
        allow(imap).to receive(:index).with(999) { imap_index }
        allow(enumerator).to receive(:each) { ["message"].enum_for(:each) }
      end

      it "returns an Email::Mboxrd::Message" do
        expect(result).to be_a(Email::Mboxrd::Message)
      end

      it "returns the message" do
        expect(result.supplied_body).to eq("message")
      end

      context "when the message is not found" do
        let(:imap_index) { nil }

        it "returns nil" do
          expect(result).to be nil
        end
      end

      context "when the supplied UID is a string" do
        let(:uid) { "999" }

        it "works" do
          expect(result).to be_a(Email::Mboxrd::Message)
        end
      end
    end

    describe "#load_nth" do
      let(:imap_index) { 0 }
      let(:result) { subject.load_nth(imap_index) }

      before do
        allow(enumerator).to receive(:each) { ["message"].enum_for(:each) }
      end

      it "returns an Email::Mboxrd::Message" do
        expect(result).to be_a(Email::Mboxrd::Message)
      end

      it "returns the message" do
        expect(result.supplied_body).to eq("message")
      end

      context "when the message is not found" do
        let(:imap_index) { 1 }

        it "returns nil" do
          expect(result).to be nil
        end
      end
    end

    describe "#each_message" do
      let(:good_uid) { 999 }

      before do
        allow(imap).to receive(:index) { nil }
        allow(imap).to receive(:index).with(good_uid) { 0 }
        allow(enumerator).to receive(:each) { ["message"].enum_for(:each) }
      end

      it "yields matching UIDs" do
        expect { |b| subject.each_message([good_uid], &b) }.
          to yield_successive_args([good_uid, anything])
      end

      it "yields matching messages" do
        messages = subject.each_message([good_uid]).map { |_uid, message| message }
        expect(messages[0].supplied_body).to eq("message")
      end

      context "with UIDs that are not present" do
        it "skips them" do
          expect { |b| subject.each_message([good_uid, 1234], &b) }.
            to yield_successive_args([good_uid, anything])
        end
      end

      context "when called without a block" do
        it "returns an Enumerator" do
          expect(subject.each_message([])).to be_a(Enumerator)
        end
      end
    end
  end
end
