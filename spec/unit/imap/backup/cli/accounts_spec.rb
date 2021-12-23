require "imap/backup/cli/accounts"

describe Imap::Backup::CLI::Accounts do
  subject { described_class.new }

  let(:accounts) { [account1, account2] }
  let(:account1) do
    instance_double(
      Imap::Backup::Account,
      username: "a1@example.com"
    )
  end
  let(:account2) do
    instance_double(
      Imap::Backup::Account,
      username: "a2@example.com"
    )
  end
  let(:store) do
    instance_double(Imap::Backup::Configuration, accounts: accounts)
  end
  let(:exists) { true }

  before do
    allow(Imap::Backup::Configuration).to receive(:new) { store }
    allow(Imap::Backup::Configuration).
      to receive(:exist?) { exists }
  end

  describe "#each" do
    specify "calls the block with each account" do
      result = subject.map { |a| a }

      expect(result).to eq(accounts)
    end

    context "when the configuration file is missing" do
      let(:exists) { false }

      it "fails" do
        expect do
          subject.each {}
        end.to raise_error(Imap::Backup::ConfigurationNotFound, /not found/)
      end
    end
  end
end
