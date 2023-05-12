require "features/helper"

RSpec.describe "imap-backup help", type: :aruba do
  context "when subcommands are invoked with a method" do
    it "outputs the method's help" do
      run_command_and_stop "imap-backup help remote namespaces"

      expect(last_command_started).to have_output(/Options:/)
    end
  end
end
