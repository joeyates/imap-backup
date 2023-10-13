require "imap/backup/setup/email"

module Imap::Backup
  RSpec.describe Setup::Email do
    subject { described_class.new(account: account, config: config) }

    let(:account) do
      instance_double(
        Account,
        username: existing_email,
        server: current_server
      )
    end
    let(:account1) do
      instance_double(Account, username: other_email)
    end
    let(:accounts) { [account, account1] }
    let(:existing_email) { "user@example.com" }
    let(:new_email) { "foo@example.com" }
    let(:other_email) { "other@example.com" }
    let(:current_server) { "imap.example.com" }
    let(:config) { instance_double(Configuration, accounts: accounts) }

    before do
      allow(Kernel).to receive(:puts)
      allow(account).to receive(:"username=")
      allow(account).to receive(:"server=")
      allow(Setup::Asker).to receive(:email) { new_email }

      subject.run
    end

    it "shows the current email" do
      expect(Setup::Asker).to have_received(:email).with(existing_email)
    end

    context "when the server is blank" do
      [
        ["GMail", "foo@gmail.com", "imap.gmail.com"],
        ["Fastmail", "bar@fastmail.fm", "imap.fastmail.com"],
        ["Fastmail", "bar@fastmail.com", "imap.fastmail.com"]
      ].each do |service, email, expected|
        context service do
          let(:new_email) { email }

          context "with nil" do
            let(:current_server) { nil }

            it "sets a default server" do
              expect(account).to have_received(:"server=").with(expected)
            end
          end

          context "with an empty string" do
            let(:current_server) { "" }

            it "sets a default server" do
              expect(account).to have_received(:"server=").with(expected)
            end
          end
        end
      end

      context "when the domain is unrecognized" do
        let(:current_server) { nil }
        let(:provider) do
          instance_double(Email::Provider, provider: :default)
        end

        before do
          allow(Email::Provider).to receive(:for_address) { provider }
        end

        it "does not set a default server" do
          expect(account).to_not have_received(:"server=")
        end
      end
    end

    context "when the email is new" do
      it "modifies the email address" do
        expect(account).to have_received(:"username=").with(new_email)
      end
    end

    context "when the email already exists" do
      let(:new_email) { other_email }

      it "indicates the error" do
        expect(Kernel).to have_received(:puts).
          with("There is already an account set up with that email address")
      end

      it "doesn't set the email" do
        expect(account.username).to eq(existing_email)
      end
    end
  end
end
