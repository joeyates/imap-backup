require "features/helper"

RSpec.describe "Mirroring", type: :aruba, docker: true do
  include_context "message-fixtures"

  let(:folder) { "my_folder" }
  let(:source_account) do
    {
      username: "address@example.com",
      password: "pass",
      mirror_mode: true,
      local_path: File.join(config_path, "source"),
      connection_options: {
        port: 8993,
        ssl: {verify_mode: 0}
      }
    }
  end
  let(:destination_account) do
    {
      username: "email@other.org",
      password: "pass",
      local_path: File.join(config_path, "destination"),
      connection_options: {
        port: 9993,
        ssl: {verify_mode: 0}
      }
    }
  end

  before do
    test_server.create_folder folder
    test_server.send_email folder, msg1

    create_config accounts: [source_account, destination_account]

    run_command_and_stop "imap-backup mirror #{source_account[:username]} #{destination_account[:username]}"
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
  end

  it "backs up the source account" do
    content = mbox_content(source_account[:username], folder)

    expect(content).to eq(to_mbox_entry(**msg1))
  end
end
