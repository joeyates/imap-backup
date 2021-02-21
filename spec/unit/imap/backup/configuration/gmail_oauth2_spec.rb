describe Imap::Backup::Configuration::GmailOauth2 do
  include HighLineTestHelpers

  CLIENT_ID = "my_client_id".freeze
  CLIENT_SECRET = "my_client_secret".freeze

  subject { described_class.new(account) }

  let(:authorization_url) { "some long authorization_url" }
  let(:credentials) { "credentials" }
  let(:json_token) { '{"sentinel":"foo"}' }
  let!(:highline_streams) { prepare_highline }
  let(:highline) { Imap::Backup::Configuration::Setup.highline }
  let(:input) { highline_streams[0] }
  let(:output) { highline_streams[1] }
  let(:account) { {} }
  let(:user_input) { %W(my_client_id\n my_secret\n my_code\n) }

  let(:authorizer) do
    instance_double(
      Google::Auth::UserAuthorizer,
      get_authorization_url: authorization_url,
      get_and_store_credentials_from_code: credentials
    )
  end
  let(:token_store) do
    instance_double(
      Google::Auth::Stores::InMemoryTokenStore,
      load: json_token
    )
  end
  let(:token) do
    instance_double(
      Gmail::Authenticator::ImapBackupToken,
      valid?: valid,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET
    )
  end
  let(:valid) { false }

  before do
    allow(Google::Auth::UserAuthorizer).
      to receive(:new) { authorizer }
    allow(Google::Auth::Stores::InMemoryTokenStore).
      to receive(:new) { token_store }
    allow(Gmail::Authenticator::ImapBackupToken).
      to receive(:new) { token }

    allow(highline).to receive(:ask).and_call_original
    allow(highline).to receive(:agree).and_call_original

    allow(Kernel).to receive(:system)
    allow(Kernel).to receive(:puts)

    allow(input).to receive(:gets).and_return(*user_input)
  end

  describe "#run" do
    let!(:result) { subject.run }

    it "clears the screen" do
      expect(Kernel).to have_received(:system).with("clear")
    end

    it "requests client_id" do
      expect(highline).to have_received(:ask).with("client_id: ")
    end

    it "requests client_secret" do
      expect(highline).to have_received(:ask).with("client_secret: ")
    end

    it "displays the authorization URL" do
      expect(Kernel).
        to have_received(:puts).
        with(/#{authorization_url}/)
    end

    it "requests the success code" do
      expect(highline).to have_received(:ask).with("success code: ")
    end

    it "requests an access_token via the code" do
      expect(authorizer).to have_received(:get_and_store_credentials_from_code)
    end

    it "returns the credentials" do
      expect(result).to match('"sentinel":"foo"')
    end

    it "includes the client_secret in the credentials" do
      expect(result).to match('"client_secret":"my_secret"')
    end

    context "when the account already has client info" do
      let(:valid) { true }
      let(:user_input) { %W(yes\n) }

      it "requests confirmation of client info" do
        expect(highline).to have_received(:agree).with("Use existing client info?")
      end

      context "when yhe user says 'no'" do
        let(:user_input) { %W(no\n) }

        it "requests client_id" do
          expect(highline).to have_received(:ask).with("client_id: ")
        end

        it "requests client_secret" do
          expect(highline).to have_received(:ask).with("client_secret: ")
        end

        it "requests the success code" do
          expect(highline).to have_received(:ask).with("success code: ")
        end
      end
    end
  end
end
