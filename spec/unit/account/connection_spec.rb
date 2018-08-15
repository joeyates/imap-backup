require "spec_helper"

describe Imap::Backup::Account::Connection do
  def self.backup_folder
    "backup_folder"
  end

  def self.folder_config
    {name: backup_folder}
  end

  let(:imap) do
    double("Net::IMAP", login: nil, list: imap_folders, disconnect: nil)
  end
  let(:imap_folders) { [] }
  let(:options) do
    {
      username: username,
      password: "password",
      local_path: local_path,
      folders: backup_folders,
    }
  end
  let(:local_path) { "local_path" }
  let(:backup_folders) { [self.class.folder_config] }
  let(:username) { "username@gmail.com" }

  before do
    allow(Net::IMAP).to receive(:new).and_return(imap)
    allow(Imap::Backup::Utils).to receive(:make_folder)
  end

  subject { described_class.new(options) }

  shared_examples "connects to IMAP" do
    it "sets up the IMAP connection" do
      expect(Net::IMAP).to have_received(:new)
    end

    it "logs in to the imap server" do
      expect(imap).to have_received(:login)
    end
  end

  context "#initialize" do
    [
      [:username, "username@gmail.com"],
      [:local_path, "local_path"],
      [:backup_folders, [folder_config]]
    ].each do |attr, expected|
      it "expects #{attr}" do
        expect(subject.send(attr)).to eq(expected)
      end
    end

    it "creates the path" do
      subject.username
      expect(Imap::Backup::Utils).to have_received(:make_folder)
    end
  end

  describe "#imap" do
    before { @result = subject.imap }

    it "returns the IMAP connection" do
      expect(@result).to eq(imap)
    end

    include_examples "connects to IMAP"
  end

  context "#folders" do
    let(:imap_folders) do
      [instance_double(Net::IMAP::MailboxList)]
    end

    it "returns the list of folders" do
      expect(subject.folders).to eq(imap_folders)
    end
  end

  context "#status" do
    let(:folder) { double("folder", uids: [remote_uid]) }
    let(:local_uid) { "local_uid" }
    let(:serializer) { double("serializer", uids: [local_uid]) }
    let(:remote_uid) { "remote_uid" }

    before do
      allow(Imap::Backup::Account::Folder).to receive(:new).and_return(folder)
      allow(Imap::Backup::Serializer::Directory).to receive(:new) { serializer }
    end

    it "should return the names of folders" do
      expect(subject.status[0][:name]).to eq(self.class.backup_folder)
    end

    it "returns local message uids" do
      expect(subject.status[0][:local]).to eq([local_uid])
    end

    it "should retrieve the available uids" do
      expect(subject.status[0][:remote]).to eq([remote_uid])
    end
  end

  context "#run_backup" do
    let(:folder) { double("folder", name: "folder") }
    let(:serializer) { double("serializer") }
    let(:downloader) { double(Imap::Backup::Downloader, run: nil) }

    before do
      allow(Imap::Backup::Downloader).
        to receive(:new).with(folder, serializer) { downloader }
    end

    context "with supplied backup_folders" do
      before do
        allow(Imap::Backup::Account::Folder).to receive(:new).
          with(subject, self.class.backup_folder).and_return(folder)
        allow(Imap::Backup::Serializer::Mbox).to receive(:new).
          with(local_path, self.class.backup_folder).and_return(serializer)
      end

      before { subject.run_backup }

      it "runs the downloader" do
        expect(downloader).to have_received(:run)
      end
    end

    context "without supplied backup_folders" do
      let(:imap_folders) do
        [instance_double(Net::IMAP::MailboxList, name: "foo")]
      end

      before do
        allow(Imap::Backup::Account::Folder).to receive(:new).
          with(subject, "foo").and_return(folder)
        allow(Imap::Backup::Serializer::Mbox).to receive(:new).
          with(local_path, "foo").and_return(serializer)
      end

      context "when supplied backup_folders is nil" do
        let(:backup_folders) { nil }

        before { subject.run_backup }

        it "runs the downloader for each folder" do
          expect(downloader).to have_received(:run).exactly(:once)
        end
      end

      context "when supplied backup_folders is an empty list" do
        let(:backup_folders) { [] }

        before { subject.run_backup }

        it "runs the downloader for each folder" do
          expect(downloader).to have_received(:run).exactly(:once)
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
  end

  context "#disconnect" do
    before { subject.disconnect }

    it "disconnects from the server" do
      expect(imap).to have_received(:disconnect)
    end

    include_examples "connects to IMAP"
  end
end
