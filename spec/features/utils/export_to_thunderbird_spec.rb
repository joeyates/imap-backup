require "features/helper"

RSpec.describe "imap-backup utils export-to-thunderbird", type: :aruba, docker: true do
  include_context "message-fixtures"

  let(:account) { test_server_connection_parameters }
  let(:email) { account[:username] }
  let(:config_options) { {accounts: [account]} }
  let(:root_path) { File.expand_path("~/.thunderbird") }
  let(:write_thunderbird_profiles_ini) do
    FileUtils.mkdir_p root_path
    path = File.join(root_path, "profiles.ini")
    content = <<~PROFILES
      [Install0]
      Name=default
      Default=Profiles/qioxtndq.default

      [Profile1]
      IsRelative=1
      Path=#{profile_path}
    PROFILES
    File.write(path, content)
  end
  let(:write_serialized_folder) do
    create_directory account[:local_path]
    message = "Email content"
    valid_imap_data = {
      version: 3, uid_validity: 1, messages: [{uid: 1, offset: 0, length: message.length}]
    }
    imap_path = File.join(account[:local_path], "Foo.imap")
    mbox_path = File.join(account[:local_path], "Foo.mbox")
    File.write(imap_path, valid_imap_data.to_json)
    File.write(mbox_path, message)
  end
  let(:profile_path) { "Profiles/qioxtndq.default" }
  let(:folder_path) do
    File.join(root_path, profile_path, "Mail/Local Folders/imap-backup.sbd", "#{email}.sbd", "Foo")
  end
  let!(:setup) do
    write_thunderbird_profiles_ini
    write_serialized_folder
    create_config(**config_options)
  end

  it "exports emails" do
    run_command_and_stop "imap-backup utils export-to-thunderbird #{email}"

    content = File.read(folder_path)
    expect(content).to include("Email content")
  end

  context "when Thunderbird is not installed" do
    let(:setup) {}

    it "fails" do
      run_command "imap-backup utils export-to-thunderbird #{email}"
      last_command_started.stop

      expect(last_command_started).to_not have_exit_status(0)
    end
  end

  context "when a config path is supplied"
end
