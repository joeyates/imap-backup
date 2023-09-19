require "features/helper"

RSpec.describe "imap-backup local check", type: :aruba do
  let(:account) { test_server_connection_parameters }
  let(:email) { account[:username] }
  let(:config_options) { {accounts: [account]} }
  let(:folder) { "my_folder" }
  let(:imap_pathname) { imap_path(email, folder) }
  let(:mbox_pathname) { mbox_path(email, folder) }
  let(:command) { "imap-backup local check" }
  let(:run!) { run_command_and_stop command }

  before do
    create_config(**config_options)
    append_local uid: 1, email: email, folder: folder, subject: "Message 1"
    append_local uid: 2, email: email, folder: folder, subject: "Message 2"
  end

  it "confirms backed-up account folder data is correct" do
    run!

    expect(last_command_started).to have_output(/my_folder: OK/)
  end

  context "when JSON is requested" do
    let(:command) { "imap-backup local check --format json" }

    it "produces JSON output" do
      run!

      expect(last_command_started).to have_output(/{"name":"my_folder","result":"OK"}/)
    end
  end

  context "when a folder's .imap file does not contain valid JSON" do
    it "indicates that the local folder backup is corrupt" do
      File.write(imap_pathname, "Some random text")

      run!

      expect(last_command_started).
        to have_output(/my_folder\.imap.*? is corrupt/)
    end
  end

  context "when a folder's .imap file does not contain ordered offsets" do
    it "indicates that the local folder backup is corrupt" do
      imap = JSON.parse(File.read(imap_pathname))
      imap["messages"][0]["offset"] = 300
      File.write(imap_pathname, imap.to_json)

      run!

      expect(last_command_started).
        to have_output(/my_folder\.imap.*? has offset data which is out of order/)
    end
  end

  context "when a folder's .mbox file is missing" do
    it "indicates that the local folder backup is corrupt" do
      File.unlink(mbox_pathname)

      run!

      expect(last_command_started).
        to have_output(/\.mbox file .*? is missing/)
    end
  end

  context "when an mbox does not contain all the expected emails" do
    it "indicates that the local folder backup is corrupt" do
      imap = JSON.parse(File.read(imap_pathname))
      imap["messages"] << {"uid" => 3, "offset" => 151, "length" => 75, "flags" => []}
      File.write(imap_pathname, imap.to_json)

      run!

      expect(last_command_started).
        to have_output(/is shorter than indicated by \.imap file/)
    end
  end

  context "when an mbox contains data after the last expected email" do
    it "indicates that the local folder backup is corrupt" do
      mbox = File.read(mbox_pathname)
      File.write(mbox_pathname, "#{mbox} SOME EXTRA STUFF")

      run!

      expect(last_command_started).
        to have_output(/is longer than indicated by \.imap file/)
    end
  end

  context "when an email in an mbox does not start at the expected offsets" do
    it "indicates that the local folder backup is corrupt" do
      imap = JSON.parse(File.read(imap_pathname))
      imap["messages"][0]["length"] -= 1
      imap["messages"][1]["offset"] -= 1
      imap["messages"][1]["length"] += 1
      File.write(imap_pathname, imap.to_json)

      run!

      expect(last_command_started).
        to have_output(/Message 2 not found at expected offset/)
    end
  end

  context "with the --delete-corrupt flag" do
    let(:command) { "imap-backup local check --delete-corrupt" }

    it "deletes corrupted folders" do
      File.unlink(mbox_pathname)

      run!

      expect(File.exist?(imap_pathname)).to be(false)
    end

    it "reports the deletion" do
      File.unlink(mbox_pathname)

      run!

      expect(last_command_started).
        to have_output(/is missing and has been deleted/)
    end
  end
end
