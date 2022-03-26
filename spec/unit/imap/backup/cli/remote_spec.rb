module Imap::Backup
  describe CLI::Remote do
    subject { described_class.new }

    let(:connection) do
      instance_double(Account::Connection, account: account, folder_names: %w[foo])
    end
    let(:account) { instance_double(Account, username: "user") }
    let(:accounts) { [account] }

    before do
      allow(CLI::Accounts).to receive(:new) { accounts }
      allow(Account::Connection).to receive(:new) { connection }
      allow(Kernel).to receive(:puts)

      subject.folders(account.username)
    end

    it "prints counts of emails to be backed up" do
      expect(Kernel).to have_received(:puts).with('"foo"')
    end
  end
end
