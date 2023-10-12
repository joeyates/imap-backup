require "imap/backup/account/client_factory"

require "imap/backup/account"

module Imap::Backup
  RSpec.describe Account::ClientFactory do
    subject { described_class.new(account: account) }

    let(:account) do
      instance_double(
        Account,
        connection_options: nil,
        username: username,
        password: "password",
        server: "server"
      )
    end
    let(:client) { instance_double(Client::Default) }
    let(:username) { "username@example.com" }
    let(:result) { subject.run }

    before do
      allow(Client::Default).to receive(:new) { client }
      allow(client).to receive(:login).with(no_args)
    end

    it "returns the AutomaticLoginWrapper" do
      expect(result).to be_a(Client::AutomaticLoginWrapper)
    end

    context "when the provider is Apple" do
      let(:username) { "user@mac.com" }
      let(:apple_client) { instance_double(Client::AppleMail, login: nil) }

      before do
        allow(Client::AppleMail).to receive(:new) { apple_client }
      end

      it "returns the Apple client" do
        expect(result.client).to eq(apple_client)
      end
    end
  end
end
