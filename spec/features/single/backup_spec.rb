require "features/helper"

RSpec.describe "imap-backup single backup", :container, type: :aruba do
  include_context "message-fixtures"

  let(:folder) { "single-backup" }
  let(:messages_as_mbox) do
    to_mbox_entry(**message_one) + to_mbox_entry(**message_two)
  end
  let(:account) { test_server_connection_parameters }
  let(:connection_options) { account[:connection_options].to_json }
  let(:command) do
    "imap-backup single backup " \
      "--email #{account[:username]} " \
      "--password #{account[:password]} " \
      "--server #{account[:server]} " \
      "--path #{account[:local_path]} " \
      "--connection-options '#{connection_options}'"
  end

  before do
    test_server.warn_about_non_default_folders
    test_server.create_folder folder
    test_server.send_email folder, **message_one
    test_server.send_email folder, **message_two
  end

  after do
    test_server.delete_folder folder
    test_server.disconnect
  end

  it "downloads messages" do
    run_command_and_stop command

    actual = mbox_content(account[:username], folder, local_path: account[:local_path])
    expect(actual).to eq(messages_as_mbox)
  end

  context "in mirror mode" do
    let(:imap_path) { File.join(account[:local_path], "Foo.imap") }
    let(:mbox_path) { File.join(account[:local_path], "Foo.mbox") }
    let(:command) { "#{super()} --mirror" }

    before do
      create_directory account[:local_path]
      File.write(imap_path, "existing imap")
      File.write(mbox_path, "existing mbox")
    end

    context "with folders that are not being backed up" do
      it "deletes .imap files" do
        run_command_and_stop command

        expect(File.exist?(imap_path)).to be false
      end

      it "deletes .mbox files" do
        run_command_and_stop command

        expect(File.exist?(mbox_path)).to be false
      end
    end
  end
end
