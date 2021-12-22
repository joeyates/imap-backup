shared_context "imap-backup connection" do
  let(:local_backup_path) { Dir.mktmpdir(nil, "tmp") }
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
  let(:connection) { Imap::Backup::Account::Connection.new(account) }
end
