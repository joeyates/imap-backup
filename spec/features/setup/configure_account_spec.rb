require "features/helper"

RSpec.describe "imap-backup setup - configuring accounts", :docker, type: :aruba do
  let(:account) { test_server_connection_parameters }
  let(:email) { account[:username] }
  let(:config_options) { {accounts: [account]} }
  let!(:setup) { create_config(**config_options) }

  it "shows account menus" do
    run_command "imap-backup setup"
    last_command_started.write "#{email}\n"
    last_command_started.write "q\n"
    last_command_started.write "q\n"
    last_command_started.stop

    expect(last_command_started).to have_output(/imap-backup - Account/m)
    expect(last_command_started).to have_output(/email\s+#{account[:username]}/)
  end

  it "tests the connection" do
    run_command "imap-backup setup"
    last_command_started.write "#{email}\n"
    last_command_started.write "test connection\n"
    last_command_started.write "\n"
    last_command_started.write "q\n"
    last_command_started.write "q\n"
    last_command_started.stop

    expect(last_command_started).to have_output(/Connection successful/m)
  end

  context "when the account's local_path has backslashes" do
    let(:account) do
      super().merge(local_path: local_path)
    end
    let(:local_path) { "c:\\my_user\\backup" }

    it "displays the path correctly" do
      run_command "imap-backup setup"
      last_command_started.write "#{email}\n"
      last_command_started.write "q\n"
      last_command_started.write "q\n"
      last_command_started.stop

      # To match literal 'c:\my_user\backup', we have to escape twice!
      escaped_local_path = local_path.gsub("\\", "\\\\\\\\")

      expect(last_command_started).to have_output(/path\s+#{escaped_local_path}/)
      expect(last_command_started).to have_exit_status(0)
    end
  end

  context "when the account's connection_options are set" do
    let(:account) do
      super().merge(connection_options: connection_options)
    end
    let(:connection_options) { {"port" => 600} }

    it "shows them" do
      run_command "imap-backup setup"
      last_command_started.write "#{email}\n"
      last_command_started.write "q\n"
      last_command_started.write "q\n"
      last_command_started.stop

      expect(last_command_started).
        to have_output(/connection options\s+'#{connection_options.to_json}'/)
      expect(last_command_started).to have_exit_status(0)
    end
  end

  context "when the account's folder list is changed" do
    context "when the existing account has configued folders" do
      let(:account) do
        super().merge(folders: [])
      end

      it "indicates the account is modified" do
        run_command "imap-backup setup"
        last_command_started.write "#{email}\n"
        last_command_started.write "9\n"
        last_command_started.write "1\n"
        last_command_started.write "q\n"
        last_command_started.write "q\n"
        last_command_started.write "4\n"
        last_command_started.stop

        puts "last_command_started.output: #{last_command_started.output}"
        expect(last_command_started).to have_output(/Account\*/)
      end
    end

    context "when the existing account does not have configued folders" do
      let(:account) do
        super().tap { |a| a.delete(:folders) }
      end

      it "does not throw errors" do
        run_command "imap-backup setup"
        last_command_started.write "#{email}\n"
        last_command_started.write "9\n"
        last_command_started.write "q\n"
        last_command_started.write "q\n"
        last_command_started.write "4\n"
        last_command_started.stop

        puts "last_command_started.output: #{last_command_started.output}"
        expect(last_command_started).to have_exit_status(0)
      end
    end
  end
end
