describe Imap::Backup::Configuration::List do
  subject { described_class.new }

  let(:accounts) do
    [
      {username: "a1@example.com"},
      {username: "a2@example.com"}
    ]
  end
  let(:store) do
    instance_double(Imap::Backup::Configuration::Store, accounts: accounts)
  end
  let(:exists) { true }
  let(:connection1) do
    instance_double(Imap::Backup::Account::Connection, disconnect: nil)
  end
  let(:connection2) do
    instance_double(Imap::Backup::Account::Connection, disconnect: nil)
  end

  before do
    allow(Imap::Backup::Configuration::Store).to receive(:new) { store }
    allow(Imap::Backup::Configuration::Store).
      to receive(:exist?) { exists }
    allow(Imap::Backup::Account::Connection).
      to receive(:new).with(accounts[0]) { connection1 }
    allow(Imap::Backup::Account::Connection).
      to receive(:new).with(accounts[1]) { connection2 }
  end

  describe "#each_connection" do
    specify "calls the block with each account's connection" do
      connections = []

      subject.each_connection { |a| connections << a }

      expect(connections).to eq([connection1, connection2])
    end

    context "with account parameter" do
      subject { described_class.new(["a2@example.com"]) }

      it "only creates requested accounts" do
        connections = []

        subject.each_connection { |a| connections << a }

        expect(connections).to eq([connection2])
      end
    end

    context "when the configuration file is missing" do
      let(:exists) { false }

      it "fails" do
        expect do
          subject.each_connection {}
        end.to raise_error(Imap::Backup::ConfigurationNotFound, /not found/)
      end
    end
  end
end
