require "imap/backup/account/local_only_folder_deleter"

module Imap::Backup
  describe Account::LocalOnlyFolderDeleter do
    subject { described_class.new(account: account) }

    let(:account) { instance_double(Account, client: nil) }
    let(:backup_folders) { instance_double(Account::BackupFolders, map: online_folders) }
    let(:online_folders) { %w(server_only both) }
    let(:serialized_folders) { instance_double(Account::SerializedFolders) }
    let(:disk_only) { instance_double(Serializer, "disk_only", folder: "disk_only", delete: nil) }
    let(:both) { instance_double(Serializer, "both", folder: "both", delete: nil) }

    before do
      allow(Account::BackupFolders).to receive(:new) { backup_folders }
      allow(Account::SerializedFolders).to receive(:new) { serialized_folders }
      allow(serialized_folders).to receive(:each).
        and_yield(disk_only, "folder").
        and_yield(both, "folder")
    end

    context "with serialized folders" do
      context "when they are not on the server" do
        it "deletes them" do
          subject.run

          expect(disk_only).to have_received(:delete)
        end
      end

      context "when they are on the server" do
        it "doesn't delete them" do
          subject.run

          expect(both).to_not have_received(:delete)
        end
      end
    end
  end
end
