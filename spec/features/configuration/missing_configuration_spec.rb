require "features/helper"

RSpec.describe "Running commands", type: :aruba do
  before do
    run_command("imap-backup")
    last_command_started.stop
  end

  context "when the configuration file is missing" do
    it "fails" do
      expect(last_command_started).not_to have_exit_status(0)
    end
  end
end
