require "features/helper"
require "imap/backup/cli/status"

RSpec.describe "status", type: :feature, docker: true do
  include_context "imap-backup connection"
  include_context "message-fixtures"

  context "when there are non-backed-up messages" do
    let(:options) do
      {accounts: "address@example.org"}
    end
    let(:folder) { "my-stuff" }
    let(:backup_folders) { [{name: folder}] }
    let(:email1) { send_email folder, msg1 }

    before do
      allow(Imap::Backup::CLI::Accounts).to receive(:new) { [account] }
      server_create_folder folder
      email1
    end

    after do
      FileUtils.rm_rf local_backup_path
      delete_emails folder
      server_delete_folder folder
      connection.disconnect
    end

    it "prints the number" do
      expect do
        Imap::Backup::CLI::Status.new(options).run
      end.to output("address@example.org\nmy-stuff: 1\n").to_stdout
    end
  end
end
