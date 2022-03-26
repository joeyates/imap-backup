require "features/helper"
require "imap/backup/cli/status"

RSpec.describe "status", type: :aruba, docker: true do
  include_context "account fixture"
  include_context "message-fixtures"

  let(:options) { {accounts: account.username} }

  context "when there are non-backed-up messages" do
    let(:folder) { "my-stuff" }
    let(:backup_folders) { [{name: folder}] }
    let(:email1) { send_email folder, msg1 }

    before do
      create_config(accounts: [account.to_h])
      server_create_folder folder
      email1
    end

    after do
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
