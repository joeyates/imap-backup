require "ostruct"

module Imap::Backup
  shared_examples "ensures the backup directory exists" do
    context "when local_path is not set" do
      let(:local_path) { nil }

      it "fails" do
        expect { action.call }.to raise_error(RuntimeError, /backup path.*?not set/)
      end
    end

    context "when the directory does not exist" do
      before do
        allow(Utils).to receive(:make_folder)

        action.call
      end

      it "creates it" do
        expect(Utils).to have_received(:make_folder)
      end
    end
  end

  describe Account::Connection do
    subject { described_class.new(account) }

    let(:imap_folders) { ["backup_folder"] }
    let(:account) do
      instance_double(
        Account,
        username: "username",
        client: client,
        local_path: local_path,
        mirror_mode: false,
        multi_fetch_size: multi_fetch_size,
        reset_seen_flags_after_fetch: reset_seen_flags_after_fetch
      )
    end
    let(:client) do
      instance_double(
        Client::Default, authenticate: nil, login: nil
      )
    end
    let(:local_path) { "local_path" }
    let(:multi_fetch_size) { 1 }
    let(:reset_seen_flags_after_fetch) { nil }
    let(:root_info) do
      instance_double(Net::IMAP::MailboxList, name: root_name)
    end
    let(:root_name) { "foo" }
    let(:serializer) do
      instance_double(
        Serializer,
        folder: serialized_folder,
        force_uid_validity: nil,
        apply_uid_validity: new_uid_validity,
        uids: [local_uid]
      )
    end
    let(:local_uid) { "local_uid" }
    let(:serialized_folder) { nil }
    let(:server) { SERVER }
    let(:new_uid_validity) { nil }
    let(:imap_folder) { "imap_folder" }
    let(:backup_folders) { instance_double(Account::Connection::BackupFolders, run: [folder]) }
    let(:folder) { instance_double(Account::Folder, name: imap_folder) }

    before do
      allow(Account::Connection::BackupFolders).to receive(:new) { backup_folders }
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
          with(local_path, imap_folder) { serializer }
      end

      it_behaves_like "ensures the backup directory exists" do
        let(:action) { -> { subject.run_backup } }
      end

      it "passes the multi_fetch_size" do
        subject.run_backup

        expect(Downloader).to have_received(:new).
          with(anything, anything, {multi_fetch_size: 10, reset_seen_flags_after_fetch: nil})
      end

      context "when reset_seen_flags_after_fetch is set" do
        let(:reset_seen_flags_after_fetch) { true }

        it "passes reset_seen_flags_after_fetch" do
          subject.run_backup

          expect(Downloader).to have_received(:new).
            with(anything, anything, {multi_fetch_size: 10, reset_seen_flags_after_fetch: true})
        end
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
        let(:imap_folders) { [root_name] }

        before do
          allow(Serializer).to receive(:new).
            with(local_path, root_name) { serializer }
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

      context "when a folder name is badly encoded" do
        it "skips the folder" do
          allow(folder).to receive(:exist?).and_raise(Encoding::UndefinedConversionError)

          subject.run_backup

          expect(downloader).to_not have_received(:run)
        end
      end
    end

    describe "#restore" do
      let(:uploader) { instance_double(Uploader, run: nil) }
      let(:folder_name) { "my_folder" }

      before do
        allow(Uploader).to receive(:new) { uploader }
        allow(Account::Folder).to receive(:new).
          with(client, folder_name) { folder }
        allow(Serializer).to receive(:new).
          with(anything, folder_name) { serializer }
        allow(Pathname).to receive(:glob).
          and_yield(Pathname.new(File.join(local_path, "#{folder_name}.imap")))
      end

      it "runs the uploader" do
        subject.restore

        expect(uploader).to have_received(:run)
      end
    end
  end
end
