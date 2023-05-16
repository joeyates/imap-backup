require "features/helper"

RSpec.describe "imap-backup version", type: :aruba do
  context "when invoked with '--version'" do
    it "outputs the version" do
      run_command_and_stop "imap-backup --version"

      expect(last_command_started).to have_output(/imap-backup \d+\.\d+\.\d+/)
    end
  end

  context "when invoked with '-v'" do
    it "outputs the version" do
      run_command_and_stop "imap-backup -v"

      expect(last_command_started).to have_output(/imap-backup \d+\.\d+\.\d+/)
    end
  end

  context "when invoked with 'version'" do
    it "outputs the version" do
      run_command_and_stop "imap-backup version"

      expect(last_command_started).to have_output(/imap-backup \d+\.\d+\.\d+/)
    end
  end
end
