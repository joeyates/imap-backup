require "features/helper"

RSpec.describe "imap-backup migrate: avoid regression in migrating legacy backups",
               :container, type: :aruba do
  def overwrite_metadata_with_old_version(email, folder)
    content = imap_parsed(email, folder)
    uids = content[:messages].map { |m| m[:uid] }
    uid_validity = content[:uid_validity]
    old_metadata = {version: 2, uids: uids, uid_validity: uid_validity}
    path = imap_path(email, folder)
    File.open(path, "w") { |f| f.write(JSON.pretty_generate(old_metadata)) }
  end

  let(:email) { "me@example.com" }
  let(:folder) { "migrate-folder" }
  let(:source_account) do
    {
      username: email,
      local_path: File.join(config_path, email.gsub("@", "_"))
    }
  end
  let(:destination_account) { test_server_connection_parameters }
  let(:destination_server) { test_server }
  let(:config_options) { {accounts: [source_account, destination_account]} }

  let!(:setup) do
    test_server.warn_about_non_default_folders
    create_config(**config_options)
    append_local(
      email: email, folder: folder, subject: "Ciao", flags: [:Draft, :$CUSTOM]
    )
    overwrite_metadata_with_old_version(email, folder)
  end

  after do
    destination_server.delete_folder folder
    destination_server.disconnect
  end

  it "copies emails to the destination account" do
    run_command_and_stop "imap-backup migrate #{email} #{destination_account[:username]}"

    messages = test_server.folder_messages(folder)
    expected = <<~MESSAGE.gsub("\n", "\r\n")
      From: sender@example.com
      Subject: Ciao

      body

    MESSAGE
    expect(messages[0]["BODY[]"]).to eq(expected)
  end
end
