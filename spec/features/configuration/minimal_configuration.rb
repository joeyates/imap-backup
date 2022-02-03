require "features/helper"

RSpec.describe "Running commands", type: :aruba do
  before do
    create_config(accounts: [])
    run_command("imap-backup local accounts")
    last_command_started.stop
  end

  context "when no accounts are configured" do
    it "succeeds" do
      expect(last_command_started).to have_exit_status(0)
    end
  end
end
