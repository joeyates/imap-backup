require "ostruct"

describe Imap::Backup::Account::Connection do
  BACKUP_FOLDER = "backup_folder"
  FOLDER_CONFIG = {name: BACKUP_FOLDER}.freeze
  FOLDER_NAME = "my_folder"
  GMAIL_IMAP_SERVER = "imap.gmail.com"
  LOCAL_PATH = "local_path"
  LOCAL_UID = "local_uid"
  PASSWORD = "secret"
  ROOT_NAME = "foo"
  SERVER = "imap.example.com"
  USERNAME = "username@example.com"

  subject { described_class.new(options) }

  let(:imap) do
    instance_double(Net::IMAP, authenticate: nil, login: nil, disconnect: nil)
  end
  let(:imap_folders) { [] }
  let(:options) do
    {
      username: USERNAME,
      password: PASSWORD,
      local_path: LOCAL_PATH,
      folders: backup_folders,
      server: server
    }
  end
  let(:backup_folders) { [FOLDER_CONFIG] }
  let(:root_info) do
    instance_double(Net::IMAP::MailboxList, name: ROOT_NAME)
  end
  let(:serializer) do
    instance_double(
      Imap::Backup::Serializer::Mbox,
      folder: serialized_folder,
      force_uid_validity: nil,
      apply_uid_validity: new_uid_validity,
      uids: [LOCAL_UID]
    )
  end
  let(:serialized_folder) { nil }
  let(:server) { SERVER }
  let(:new_uid_validity) { nil }

  before do
    allow(Net::IMAP).to receive(:new) { imap }
    allow(imap).to receive(:list).with("", "") { [root_info] }
    allow(imap).to receive(:list).with(ROOT_NAME, "*") { imap_folders }
    allow(Imap::Backup::Utils).to receive(:make_folder)
  end

  shared_examples "connects to IMAP" do
    it "logs in to the imap server" do
      expect(imap).to have_received(:login)
    end
  end

  describe "#initialize" do
    [
      [:username, USERNAME],
      [:password, PASSWORD],
      [:local_path, LOCAL_PATH],
      [:backup_folders, [FOLDER_CONFIG]],
      [:server, SERVER]
    ].each do |attr, expected|
      it "expects #{attr}" do
        expect(subject.public_send(attr)).to eq(expected)
      end
    end

    it "creates the path" do
      expect(Imap::Backup::Utils).to receive(:make_folder)

      subject.username
    end
  end

  describe "#imap" do
    let!(:result) { subject.imap }

    it "returns the IMAP connection" do
      expect(result).to eq(imap)
    end

    it "uses the password" do
      expect(imap).to have_received(:login).with(USERNAME, PASSWORD)
    end

    context "with the GMail IMAP server" do
      ACCESS_TOKEN = "access_token"

      let(:server) { GMAIL_IMAP_SERVER }
      let(:is_refresh_token) { true }
      let(:result) { nil }
      let(:authenticator) do
        instance_double(
          GMail::Authenticator,
          credentials: credentials
        )
      end
      let(:credentials) { OpenStruct.new(access_token: ACCESS_TOKEN) }

      before do
        allow(GMail::Authenticator).
          to receive(:is_refresh_token?) { is_refresh_token }
        allow(GMail::Authenticator).
          to receive(:new).
          with(email: USERNAME, token: PASSWORD) { authenticator }
      end

      context "when the password is our copy of a GMail refresh token" do
        it "uses the OAuth2 access_token to authenticate" do
          subject.imap

          expect(imap).to have_received(:authenticate).with(
            "XOAUTH2", USERNAME, ACCESS_TOKEN
          )
        end

        context "when the refresh token is invalid" do
          let(:credentials) { nil }

          it "raises" do
            expect { subject.imap }.to raise_error(String)
          end
        end
      end

      context "when the password is not our copy of a GMail refresh token" do
        let(:is_refresh_token) { false }

        it "uses the password" do
          subject.imap

          expect(imap).to have_received(:login).with(USERNAME, PASSWORD)
        end
      end
    end

    include_examples "connects to IMAP"
  end

  describe "#folders" do
    let(:imap_folders) do
      [instance_double(Net::IMAP::MailboxList)]
    end

    it "returns the list of folders" do
      expect(subject.folders).to eq(imap_folders)
    end
  end

  describe "#status" do
    let(:folder) do
      instance_double(Imap::Backup::Account::Folder, uids: [remote_uid])
    end
    let(:remote_uid) { "remote_uid" }

    before do
      allow(Imap::Backup::Account::Folder).to receive(:new) { folder }
      allow(Imap::Backup::Serializer::Mbox).to receive(:new) { serializer }
    end

    it "returns the names of folders" do
      expect(subject.status[0][:name]).to eq(BACKUP_FOLDER)
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
        Imap::Backup::Account::Folder,
        name: "folder",
        exist?: exists,
        uid_validity: uid_validity
      )
    end
    let(:exists) { true }
    let(:uid_validity) { 123 }
    let(:downloader) { instance_double(Imap::Backup::Downloader, run: nil) }

    before do
      allow(Imap::Backup::Downloader).
        to receive(:new).with(folder, serializer) { downloader }
      allow(Imap::Backup::Account::Folder).to receive(:new).
        with(subject, BACKUP_FOLDER) { folder }
      allow(Imap::Backup::Serializer::Mbox).to receive(:new).
        with(LOCAL_PATH, BACKUP_FOLDER) { serializer }
    end

    context "with supplied backup_folders" do
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

    context "without supplied backup_folders" do
      let(:imap_folders) do
        [instance_double(Net::IMAP::MailboxList, name: ROOT_NAME)]
      end

      before do
        allow(Imap::Backup::Account::Folder).to receive(:new).
          with(subject, ROOT_NAME) { folder }
        allow(Imap::Backup::Serializer::Mbox).to receive(:new).
          with(LOCAL_PATH, ROOT_NAME) { serializer }
      end

      context "when supplied backup_folders is nil" do
        let(:backup_folders) { nil }

        it "runs the downloader for each folder" do
          expect(downloader).to receive(:run).exactly(:once)

          subject.run_backup
        end
      end

      context "when supplied backup_folders is an empty list" do
        let(:backup_folders) { [] }

        it "runs the downloader for each folder" do
          expect(downloader).to receive(:run).exactly(:once)

          subject.run_backup
        end
      end

      context "when the imap server doesn't return folders" do
        let(:backup_folders) { nil }
        let(:imap_folders) { nil }

        it "does not fail" do
          expect { subject.run_backup }.to_not raise_error
        end
      end
    end

    context "imap preconnect" do
      before { subject.run_backup }

      include_examples "connects to IMAP"
    end
  end

  describe "#restore" do
    let(:folder) do
      instance_double(
        Imap::Backup::Account::Folder,
        create: nil,
        uids: uids,
        name: FOLDER_NAME,
        uid_validity: uid_validity
      )
    end
    let(:uids) { [99] }
    let(:uid_validity) { 123 }
    let(:serialized_folder) { "old name" }
    let(:uploader) do
      instance_double(Imap::Backup::Uploader, run: false)
    end
    let(:updated_uploader) do
      instance_double(Imap::Backup::Uploader, run: false)
    end
    let(:updated_folder) do
      instance_double(
        Imap::Backup::Account::Folder,
        create: nil,
        uid_validity: "new uid validity"
      )
    end
    let(:updated_serializer) do
      instance_double(
        Imap::Backup::Serializer::Mbox, force_uid_validity: nil
      )
    end

    before do
      allow(Imap::Backup::Account::Folder).to receive(:new).
        with(subject, FOLDER_NAME) { folder }
      allow(Imap::Backup::Serializer::Mbox).to receive(:new).
        with(anything, FOLDER_NAME) { serializer }
      allow(Imap::Backup::Account::Folder).to receive(:new).
        with(subject, "new name") { updated_folder }
      allow(Imap::Backup::Serializer::Mbox).to receive(:new).
        with(anything, "new name") { updated_serializer }
      allow(Imap::Backup::Uploader).to receive(:new).
        with(folder, serializer) { uploader }
      allow(Imap::Backup::Uploader).to receive(:new).
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
    it "disconnects from the server" do
      expect(imap).to receive(:disconnect)

      subject.reconnect
    end

    it "causes reconnection on future access" do
      expect(Net::IMAP).to receive(:new)

      subject.reconnect
    end
  end

  describe "#disconnect" do
    it "disconnects from the server" do
      expect(imap).to receive(:disconnect)

      subject.disconnect
    end
  end
end
