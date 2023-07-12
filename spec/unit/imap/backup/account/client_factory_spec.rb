require "imap/backup/account/client_factory"

module Imap::Backup
  describe Account::ClientFactory do
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

    it "logs in" do
      result

      expect(client).to have_received(:login)
    end

    it "returns the IMAP connection" do
      expect(result).to eq(client)
    end

    context "when the first login attempt fails" do
      before do
        outcomes = [-> { raise EOFError }, -> { true }]
        allow(client).to receive(:login) { outcomes.shift.call }
      end

      it "retries" do
        subject.run

        expect(client).to have_received(:login).twice
      end
    end

    context "when the provider is Apple" do
      let(:username) { "user@mac.com" }
      let(:apple_client) { instance_double(Client::AppleMail, login: nil) }

      before do
        allow(Client::AppleMail).to receive(:new) { apple_client }
      end

      it "returns the Apple client" do
        expect(result).to eq(apple_client)
      end
    end
  end
end
