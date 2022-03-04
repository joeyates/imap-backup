require "ostruct"

describe Imap::Backup::Account::Connection do
  BACKUP_FOLDER = "backup_folder".freeze
  FOLDER_CONFIG = {name: BACKUP_FOLDER}.freeze
  FOLDER_NAME = "my_folder".freeze
  GMAIL_IMAP_SERVER = "imap.gmail.com".freeze
  IMAP_FOLDER = "imap_folder".freeze
  LOCAL_PATH = "local_path".freeze
  LOCAL_UID = "local_uid".freeze
  PASSWORD = "secret".freeze
  ROOT_NAME = "foo".freeze
  SERVER = "imap.example.com".freeze
  USERNAME = "username@example.com".freeze

  subject { described_class.new(account) }

  let(:client) do
    instance_double(
      Imap::Backup::Client::Default, authenticate: nil, login: nil, disconnect: nil
    )
  end
  let(:imap_folders) { [] }
  let(:account) do
    instance_double(
      Imap::Backup::Account,
      username: username,
      password: PASSWORD,
      local_path: LOCAL_PATH,
      folders: config_folders,
      multi_fetch_size: multi_fetch_size,
      server: server,
      connection_options: nil
    )
  end
  let(:username) { USERNAME }
  let(:config_folders) { [FOLDER_CONFIG] }
  let(:multi_fetch_size) { 1 }
  let(:root_info) do
    instance_double(Net::IMAP::MailboxList, name: ROOT_NAME)
  end
  let(:serializer) do
    instance_double(
      Imap::Backup::Serializer,
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
    allow(Imap::Backup::Client::Default).to receive(:new) { client }
    allow(client).to receive(:list) { imap_folders }
    allow(Imap::Backup::Utils).to receive(:make_folder)
  end

  shared_examples "connects to IMAP" do
    it "logs in to the imap server" do
      expect(client).to have_received(:login)
    end
  end

  describe "#client" do
    let(:result) { subject.client }

    it "returns the IMAP connection" do
      expect(result).to eq(client)
    end

    it "uses the password" do
      result

      expect(client).to have_received(:login).with(USERNAME, PASSWORD)
    end

    context "when the first login attempt fails" do
      before do
        outcomes = [-> { raise EOFError }, -> { true }]
        allow(client).to receive(:login) { outcomes.shift.call }
      end

      it "retries" do
        subject.client

        expect(client).to have_received(:login).twice
      end
    end

    context "when the provider is Apple" do
      let(:username) { "user@mac.com" }
      let(:apple_client) do
        instance_double(
          Imap::Backup::Client::AppleMail, login: nil
        )
      end

      before do
        allow(Imap::Backup::Client::AppleMail).to receive(:new) { apple_client }
      end

      it "returns the Apple client" do
        expect(result).to eq(apple_client)
      end
    end

    context "when run" do
      before { subject.client }

      include_examples "connects to IMAP"
    end
  end

  describe "#folder_names" do
    let(:imap_folders) do
      [IMAP_FOLDER]
    end

    it "returns the list of folders" do
      expect(subject.folder_names).to eq([IMAP_FOLDER])
    end
  end

  describe "#status" do
    let(:folder) do
      instance_double(
        Imap::Backup::Account::Folder,
        uids: [remote_uid],
        name: IMAP_FOLDER
      )
    end
    let(:remote_uid) { "remote_uid" }

    before do
      allow(Imap::Backup::Account::Folder).to receive(:new) { folder }
      allow(Imap::Backup::Serializer).to receive(:new) { serializer }
    end

    it "creates the path" do
      expect(Imap::Backup::Utils).to receive(:make_folder)

      subject.status
    end

    it "returns the names of folders" do
      expect(subject.status[0][:name]).to eq(IMAP_FOLDER)
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
        name: IMAP_FOLDER,
        exist?: exists,
        uid_validity: uid_validity
      )
    end
    let(:exists) { true }
    let(:uid_validity) { 123 }
    let(:downloader) { instance_double(Imap::Backup::Downloader, run: nil) }
    let(:multi_fetch_size) { 10 }

    before do
      allow(Imap::Backup::Downloader).
        to receive(:new).with(folder, serializer, anything) { downloader }
      allow(Imap::Backup::Account::Folder).to receive(:new).
        with(subject, BACKUP_FOLDER) { folder }
      allow(Imap::Backup::Serializer).to receive(:new).
        with(LOCAL_PATH, IMAP_FOLDER) { serializer }
    end

    it "passes the multi_fetch_size" do
      subject.run_backup

      expect(Imap::Backup::Downloader).to have_received(:new).
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
        allow(Imap::Backup::Account::Folder).to receive(:new).
          with(subject, ROOT_NAME) { folder }
        allow(Imap::Backup::Serializer).to receive(:new).
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

      context "when the imap server doesn't return folders" do
        let(:config_folders) { nil }
        let(:imap_folders) { [] }

        it "fails" do
          expect do
            subject.run_backup
          end.to raise_error(RuntimeError, /Unable to get folder list/)
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

    context "when run" do
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
        name: IMAP_FOLDER,
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
        Imap::Backup::Serializer, force_uid_validity: nil
      )
    end

    before do
      allow(Imap::Backup::Account::Folder).to receive(:new).
        with(subject, FOLDER_NAME) { folder }
      allow(Imap::Backup::Serializer).to receive(:new).
        with(anything, FOLDER_NAME) { serializer }
      allow(Imap::Backup::Account::Folder).to receive(:new).
        with(subject, "new name") { updated_folder }
      allow(Imap::Backup::Serializer).to receive(:new).
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
      expect(Imap::Backup::Client::Default).to receive(:new)

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
