require "features/helper"
require "imap/backup/cli/folders"

RSpec.describe "folders", type: :feature, docker: true do
  include_context "imap-backup connection"

  let(:options) do
    {accounts: "address@example.org"}
  end
  let(:folder) { "my-stuff" }

  before do
    allow(Imap::Backup::CLI::Accounts).to receive(:new) { [account] }
    server_create_folder folder
  end

  after do
    FileUtils.rm_rf local_backup_path
    server_delete_folder folder
    connection.disconnect
  end

  it "lists account folders" do
    expect do
      Imap::Backup::CLI::Folders.new(options).run
    end.to output(/^\tmy-stuff\n/).to_stdout
  end
end
