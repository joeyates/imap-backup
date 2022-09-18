require "features/helper"

RSpec.describe "Listing account folders", type: :aruba do
  let(:email) { "me@example.com" }
  let(:account) do
    {
      username: email,
      local_path: File.join(config_path, email.gsub("@", "_"))
    }
  end
  let(:config_options) { {accounts: [account]} }
  let(:command) { "imap-backup local folders #{email}" }

  before do
    create_config **config_options
    append_local(email: email, folder: "my_folder", body: "Hi")
    run_command_and_stop command
  end

  it "lists folders that have been backed up" do
    expect(last_command_started).to have_output('"my_folder"')
  end
end
