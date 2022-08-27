module Imap::Backup
  describe Setup::BackupPath do
    include HighLineTestHelpers

    subject { described_class.new(account: account, config: config) }

    let!(:highline_streams) { prepare_highline }
    let(:stdin) { highline_streams[0] }
    let(:stdout) { highline_streams[1] }
    let(:account) do
      instance_double(
        Account,
        username: "username@example.com",
        local_path: "/backup/path"
      )
    end
    let(:account1) do
      instance_double(Account, username: "account1", local_path: other_existing_path)
    end
    let(:other_existing_path) { "/other/existing/path" }
    let(:accounts) { [account, account1] }
    let(:config) { instance_double(Configuration, accounts: accounts, path: "/config/path") }
    let(:new_backup_path) { "/new/path" }

    before do
      allow(Kernel).to receive(:puts)
      allow(account).to receive(:"local_path=")
      allow(Setup.highline).to receive(:get_response_line_mode) { new_backup_path }
    end

    context "with valid input" do
      it "asks for input" do
        subject.run

        expect(stdout.string).to match(%r(backup directory: \|/backup/path))
      end

      it "updates the path" do
        subject.run

        expect(account).to have_received(:"local_path=").with(new_backup_path)
      end
    end

    context "when the path is used by other backups" do
      before do
        allow(Setup.highline).to receive(:get_response_line_mode).
          and_return(other_existing_path, new_backup_path)
        allow(Setup.highline).to receive(:say)

        subject.run
      end

      it "fails validation" do
        expect(Setup.highline).to have_received(:say).with("Choose a different directory ")
      end

      it "accepts a valid response" do
        expect(account).to have_received(:"local_path=").with(new_backup_path)
      end
    end
  end
end
