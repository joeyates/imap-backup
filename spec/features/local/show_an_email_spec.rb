require "features/helper"

RSpec.describe "Show an email", type: :aruba do
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
    append_local(
      email: email,
      folder: "my_folder",
      uid: 99,
      from: "me@example.com",
      subject: "Hello",
      body: "How're things?"
    )

    run_command_and_stop("imap-backup local show #{email} my_folder 99")
  end

  it "shows the email" do
    expected = <<~BODY
      From: me@example.com
      Subject: Hello

      How're things?
    BODY
    expect(last_command_started).to have_output(expected)
  end
end
