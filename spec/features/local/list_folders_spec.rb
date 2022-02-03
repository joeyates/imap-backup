require "features/helper"

RSpec.describe "Listing account folders", type: :aruba do
  let(:email) { "me@example.com" }
  let(:account) do
    {
      username: email,
      local_path: File.join(config_path, email.gsub("@", "_"))
    }
  end

  before do
    create_config(accounts: [account])
    store_email(email: email, folder: "my_folder", body: "Hi")
    run_command_and_stop("imap-backup local folders #{email}")
  end

  it "lists folders that have been backed up" do
    expect(last_command_started).to have_output(%q("my_folder"))
  end
end
