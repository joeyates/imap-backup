module Imap::Backup
  describe Uploader do
    subject { described_class.new(folder, serializer) }

    let(:folder) do
      instance_double(
        Account::Folder, "Supplied Folder",
        append: 99,
        connection: "connection",
        create: nil,
        name: "imap_folder",
        uid_validity: folder_uid_validity,
        uids: folder_uids
      )
    end
    let(:folder_uids) { [] }
    let(:folder_uid_validity) { 123 }
    let(:serializer) do
      instance_double(
        Serializer, "Supplied Serializer",
        apply_uid_validity: apply_uid_validity_result,
        each_message: enum_for(:message_enumerator),
        folder: "local name",
        force_uid_validity: nil,
        path: "local/account/path",
        uids: on_disk_uids,
        update_uid: nil
      )
    end
    let(:apply_uid_validity_result) { nil }
    let(:on_disk_uids) { [99] }
    let(:missing_message) do
      instance_double(Email::Mboxrd::Message, supplied_body: "missing message")
    end

    def message_enumerator
      yield [1, missing_message]
    end

    it "creates the folder" do
      subject.run

      expect(folder).to have_received(:create)
    end

    it "sets local uid validity to the online value" do
      expect(serializer).to receive(:force_uid_validity).with(folder_uid_validity)

      subject.run
    end

    it "restores messages that are missing" do
      subject.run

      expect(folder).to have_received(:append).with(missing_message)
    end

    it "handles append failures" do
      allow(folder).to receive(:append).and_raise(RuntimeError)

      subject.run
    end

    context "with messages that are present on server" do
      let(:existing_message) do
        instance_double(Email::Mboxrd::Message, supplied_body: "existing message")
      end

      it "does nothing" do
        subject.run

        expect(folder).to_not have_received(:append).with(existing_message)
      end
    end

    it "updates the local message id for restored messages" do
      expect(serializer).to receive(:update_uid).with(1, 99)

      subject.run
    end

    context "when the folder exists with contents" do
      let(:folder_uids) { [99] }

      it "sets local uid validity" do
        subject.run

        expect(serializer).to have_received(:apply_uid_validity).with(folder_uid_validity)
      end

      context "when the local folder is renamed" do
        let(:apply_uid_validity_result) { "new name" }
        let(:renamed_folder) do
          instance_double(
            Account::Folder, "Renamed folder",
            create: nil,
            uids: folder_uids,
            uid_validity: "new uid validity"
          )
        end
        let(:updated_serializer) do
          instance_double(
            Serializer, "Updated Serializer",
            force_uid_validity: nil,
            uids: on_disk_uids
          )
        end

        before do
          allow(Account::Folder).to receive(:new).
            with(folder.connection, "new name") { renamed_folder }
          allow(Serializer).to receive(:new).
            with(serializer.path, "new name") { updated_serializer }
        end

        it "creates the new folder" do
          subject.run

          expect(renamed_folder).to have_received(:create)
        end

        it "copies the new (renamed) folder's uid validity" do
          subject.run

          expect(updated_serializer).
            to have_received(:force_uid_validity).with("new uid validity")
        end
      end
    end
  end
end
