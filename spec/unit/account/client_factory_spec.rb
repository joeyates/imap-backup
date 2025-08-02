require "imap/backup/account/client_factory"

require "imap/backup/account"

module Imap::Backup
  RSpec.describe Account::ClientFactory do
    subject { described_class.new(account: account) }

    let(:account) do
      instance_double(
        Account,
        connection_options: nil,
        username: "username@example.com",
        password: "password",
        server: "server"
      )
    end
    let(:client) { instance_double(Client::Default) }
    let(:result) { subject.run }

    before do
      allow(Client::Default).to receive(:new) { client }
      allow(client).to receive(:login).with(no_args)
    end

    it "returns the AutomaticLoginWrapper" do
      expect(result).to be_a(Client::AutomaticLoginWrapper)
    end
  end
end
