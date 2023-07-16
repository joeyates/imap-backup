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
      Default=#{profile_path}

      [Profile1]
      IsRelative=1
      Path=#{profile_path}
    PROFILES
    File.write(path, content)
  end
  let(:create_local_folders) { create_directory local_folders_path }
  let(:write_serialized_folder) do
    create_local_folder email: account[:username], folder: "Foo", uid_validity: 1
    append_local email: account[:username], folder: "Foo", body: "Email content"
  end
  let(:profile_path) { "Profiles/qioxtndq.default" }
  let(:local_folders_path) { File.join(root_path, profile_path, "Mail/Local Folders") }
  let(:folder_path) do
    File.join(local_folders_path, "imap-backup.sbd", "#{email}.sbd", "Foo")
  end
  let!(:setup) do
    create_config(**config_options)
    write_thunderbird_profiles_ini
    create_local_folders
    write_serialized_folder
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

  context "when a config path is supplied" do
    let(:custom_config_path) { File.join(File.expand_path("~/.imap-backup"), "foo.json") }
    let(:config_options) { {accounts: [account], path: custom_config_path} }
    let(:write_serialized_folder) do
      create_local_folder(
        email: account[:username],
        folder: "Foo",
        uid_validity: 1,
        configuration_path: custom_config_path
      )
      append_local(
        email: account[:username],
        folder: "Foo",
        body: "Email content",
        configuration_path: custom_config_path
      )
    end

    it "exports emails" do
      run_command_and_stop "imap-backup utils export-to-thunderbird #{email} -c #{custom_config_path}"

      content = File.read(folder_path)
      expect(content).to include("Email content")
    end
  end
end
