shared_context "account fixture" do
  let(:local_backup_path) { File.expand_path("~/backup") }
  let(:default_connection) { fixture("connection") }
  let(:backup_folders) { nil }
  let(:account) do
    Imap::Backup::Account.new(
      default_connection.merge(
        local_path: local_backup_path,
        folders: backup_folders
      )
    )
  end
end
