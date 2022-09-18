require "features/helper"

RSpec.describe "Listing emails", type: :aruba do
  let(:email) { "me@example.com" }
  let(:account) do
    {
      username: email,
      local_path: File.join(config_path, email.gsub("@", "_"))
    }
  end
  let(:config_options) { {accounts: [account]} }

  before do
    create_config **config_options
    append_local(email: email, folder: "my_folder", subject: "Ciao")
    run_command_and_stop("imap-backup local list #{email} my_folder")
  end

  it "lists emails" do
    expect(last_command_started).to have_output(/1: Ciao/)
  end
end
