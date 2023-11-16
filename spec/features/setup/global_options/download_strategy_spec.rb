require "features/helper"

RSpec.describe "imap-backup setup - global options - download strategy", type: :aruba do
  before { create_config(accounts: []) }

  it "allows setting the strategy" do
    run_command "imap-backup setup"
    last_command_started.write "modify global options\n"
    last_command_started.write "change download strategy\n"
    last_command_started.write "write straight to disk\n"
    last_command_started.write "q\n"
    last_command_started.write "q\n"
    last_command_started.write "save and exit\n"
    last_command_started.stop

    config = parsed_config
    expect(config[:download_strategy]).to eq("direct")
  end
end
