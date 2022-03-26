require "features/helper"

RSpec.describe "Migration", type: :aruba, docker: true do
  let(:email) { "me@example.com" }
  let(:folder) { "my_folder" }
  let(:source_account) do
    {
      username: email,
      local_path: File.join(config_path, email.gsub("@", "_"))
    }
  end
  let(:destination_account) { fixture("connection") }

  before do
    create_config(accounts: [source_account, destination_account])
    store_email(email: email, folder: folder, subject: "Ciao")
    run_command_and_stop("imap-backup migrate #{email} #{destination_account[:username]}")
  end

  after do
    server_delete_folder folder
    disconnect_imap
  end

  it "copies email to the destination account" do
    messages = server_messages(folder)
    expected = <<~MESSAGE.gsub("\n", "\r\n")
      From: sender@example.com
      Subject: Ciao

      body

    MESSAGE
    expect(messages[0]["BODY[]"]).to eq(expected)
  end
end
