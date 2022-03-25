require "ostruct"

module Imap::Backup
  describe Account::Connection do
    BACKUP_FOLDER = "backup_folder".freeze
    FOLDER_NAME = "my_folder".freeze
    LOCAL_PATH = "local_path".freeze
    LOCAL_UID = "local_uid".freeze
    ROOT_NAME = "foo".freeze

    subject { described_class.new(account) }

    let(:client_factory) { instance_double(Account::Connection::ClientFactory, run: client) }
    let(:client) do
      instance_double(
        Client::Default, authenticate: nil, login: nil, disconnect: nil
      )
    end
    let(:imap_folders) { ["backup_folder"] }
    let(:account) do
      instance_double(
        Account,
        username: "username",
        local_path: LOCAL_PATH,
        multi_fetch_size: multi_fetch_size
      )
    end
    let(:multi_fetch_size) { 1 }
    let(:root_info) do
      instance_double(Net::IMAP::MailboxList, name: ROOT_NAME)
    end
    let(:serializer) do
      instance_double(
        Serializer,
        folder: serialized_folder,
        force_uid_validity: nil,
        apply_uid_validity: new_uid_validity,
        uids: [LOCAL_UID]
      )
    end
    let(:serialized_folder) { nil }
    let(:server) { SERVER }
    let(:new_uid_validity) { nil }
    let(:imap_folder) { "imap_folder" }
    let(:backup_folders) { instance_double(Account::Connection::BackupFolders, run: [folder]) }
    let(:folder) { instance_double(Account::Folder, name: imap_folder) }

    before do
      allow(Account::Connection::ClientFactory).to receive(:new) { client_factory }
      allow(Account::Connection::BackupFolders).to receive(:new) { backup_folders }
      allow(Utils).to receive(:make_folder)
    end

    describe "#client" do
      it "calls ClientFactory" do
        expect(subject.client).to eq(client)
      end
    end

    describe "#folder_names" do
      let(:folder_names) { instance_double(Account::Connection::FolderNames, run: "result") }

      before do
        allow(Account::Connection::FolderNames).to receive(:new) { folder_names }
      end

      it "returns the list of folders" do
        expect(subject.folder_names).to eq("result")
      end
    end

    describe "#backup_folders" do
      let(:backup_folders) { instance_double(Account::Connection::BackupFolders, run: "result") }

      before do
        allow(Account::Connection::BackupFolders).to receive(:new) { backup_folders }
      end

      it "returns the list of folders" do
        expect(subject.backup_folders).to eq("result")
      end
    end

    describe "#status" do
      let(:folder) do
        instance_double(
          Account::Folder,
          uids: [remote_uid],
          name: imap_folder
        )
      end
      let(:remote_uid) { "remote_uid" }

      before do
        allow(Account::Folder).to receive(:new) { folder }
        allow(Serializer).to receive(:new) { serializer }
      end

      it "creates the path" do
        expect(Utils).to receive(:make_folder)

        subject.status
      end

      it "returns the names of folders" do
        expect(subject.status[0][:name]).to eq(imap_folder)
      end

      it "returns local message uids" do
        expect(subject.status[0][:local]).to eq([LOCAL_UID])
      end

      it "retrieves the available uids" do
        expect(subject.status[0][:remote]).to eq([remote_uid])
      end
    end

    describe "#run_backup" do
      let(:folder) do
        instance_double(
          Account::Folder,
          name: imap_folder,
          exist?: exists,
          uid_validity: uid_validity
        )
      end
      let(:exists) { true }
      let(:uid_validity) { 123 }
      let(:downloader) { instance_double(Downloader, run: nil) }
      let(:multi_fetch_size) { 10 }

      before do
        allow(Downloader).
          to receive(:new).with(anything, serializer, anything) { downloader }
        allow(Serializer).to receive(:new).
          with(LOCAL_PATH, imap_folder) { serializer }
      end

      it "passes the multi_fetch_size" do
        subject.run_backup

        expect(Downloader).to have_received(:new).
          with(anything, anything, {multi_fetch_size: 10})
      end

      context "with supplied config_folders" do
        it "runs the downloader" do
          expect(downloader).to receive(:run)

          subject.run_backup
        end

        context "when a folder does not exist" do
          let(:exists) { false }

          it "does not run the downloader" do
            expect(downloader).to_not receive(:run)

            subject.run_backup
          end
        end
      end

      context "without supplied config_folders" do
        let(:imap_folders) { [ROOT_NAME] }

        before do
          allow(Serializer).to receive(:new).
            with(LOCAL_PATH, ROOT_NAME) { serializer }
        end

        context "when supplied config_folders is nil" do
          let(:config_folders) { nil }

          it "runs the downloader for each folder" do
            expect(downloader).to receive(:run).exactly(:once)

            subject.run_backup
          end
        end

        context "when supplied config_folders is an empty list" do
          let(:config_folders) { [] }

          it "runs the downloader for each folder" do
            expect(downloader).to receive(:run).exactly(:once)

            subject.run_backup
          end
        end
      end

      context "when the IMAP session expires" do
        before do
          data = OpenStruct.new(data: "Session expired")
          response = OpenStruct.new(data: data)
          outcomes = [
            -> { raise Net::IMAP::ByeResponseError, response },
            -> { nil }
          ]
          allow(downloader).to receive(:run) { outcomes.shift.call }
        end

        it "reconnects" do
          expect(downloader).to receive(:run).exactly(:twice)

          subject.run_backup
        end
      end
    end

    describe "#restore" do
      let(:folder) do
        instance_double(
          Account::Folder,
          create: nil,
          uids: uids,
          name: imap_folder,
          uid_validity: uid_validity
        )
      end
      let(:uids) { [99] }
      let(:uid_validity) { 123 }
      let(:serialized_folder) { "old name" }
      let(:uploader) do
        instance_double(Uploader, run: false)
      end
      let(:updated_uploader) do
        instance_double(Uploader, run: false)
      end
      let(:updated_folder) do
        instance_double(
          Account::Folder,
          create: nil,
          uid_validity: "new uid validity"
        )
      end
      let(:updated_serializer) do
        instance_double(
          Serializer, force_uid_validity: nil
        )
      end

      before do
        allow(Account::Folder).to receive(:new).
          with(subject, FOLDER_NAME) { folder }
        allow(Serializer).to receive(:new).
          with(anything, FOLDER_NAME) { serializer }
        allow(Account::Folder).to receive(:new).
          with(subject, "new name") { updated_folder }
        allow(Serializer).to receive(:new).
          with(anything, "new name") { updated_serializer }
        allow(Uploader).to receive(:new).
          with(folder, serializer) { uploader }
        allow(Uploader).to receive(:new).
          with(updated_folder, updated_serializer) { updated_uploader }
        allow(Pathname).to receive(:glob).
          and_yield(Pathname.new(File.join(LOCAL_PATH, "#{FOLDER_NAME}.imap")))
      end

      it "sets local uid validity" do
        expect(serializer).to receive(:apply_uid_validity).with(uid_validity)

        subject.restore
      end

      context "when folders exist with contents" do
        context "when the local folder is renamed" do
          let(:new_uid_validity) { "new name" }

          it "creates the new folder" do
            expect(updated_folder).to receive(:create)

            subject.restore
          end

          it "sets the renamed folder's uid validity" do
            expect(updated_serializer).
              to receive(:force_uid_validity).with("new uid validity")

            subject.restore
          end

          it "creates the uploader with updated folder and serializer" do
            expect(updated_uploader).to receive(:run)

            subject.restore
          end
        end

        context "when the local folder is not renamed" do
          it "runs the uploader" do
            expect(uploader).to receive(:run)

            subject.restore
          end
        end
      end

      context "when folders don't exist or are empty" do
        let(:uids) { [] }

        it "creates the folder" do
          expect(folder).to receive(:create)

          subject.restore
        end

        it "forces local uid validity" do
          expect(serializer).to receive(:force_uid_validity).with(uid_validity)

          subject.restore
        end

        it "runs the uploader" do
          expect(uploader).to receive(:run)

          subject.restore
        end
      end
    end

    describe "#reconnect" do
      context "when the IMAP connection has been used" do
        before { subject.client }

        it "disconnects from the server" do
          expect(client).to receive(:disconnect)

          subject.reconnect
        end
      end

      context "when the IMAP connection has not been used" do
        it "does not disconnect from the server" do
          expect(client).to_not receive(:disconnect)

          subject.reconnect
        end
      end

      it "causes reconnection on future access" do
        expect(client_factory).to receive(:run)

        subject.reconnect
        subject.client
      end
    end

    describe "#disconnect" do
      context "when the IMAP connection has been used" do
        it "disconnects from the server" do
          subject.client

          expect(client).to receive(:disconnect)

          subject.disconnect
        end
      end

      context "when the IMAP connection has not been used" do
        it "does not disconnect from the server" do
          expect(client).to_not receive(:disconnect)

          subject.disconnect
        end
      end
    end
  end
end
