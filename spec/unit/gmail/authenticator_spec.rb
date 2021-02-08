require "gmail/authenticator"
require "googleauth"

describe Gmail::Authenticator do
  ACCESS_TOKEN = "access_token".freeze
  AUTHORIZATION_URL = "authorization_url".freeze
  CLIENT_ID = "client_id".freeze
  CLIENT_SECRET = "client_secret".freeze
  CODE = "code".freeze
  CREDENTIALS = "credentials".freeze
  EMAIL = "email".freeze
  EXPIRATION_TIME_MILLIS = "expiration_time_millis".freeze
  GMAIL_READ_SCOPE = "https://mail.google.com/".freeze
  IMAP_BACKUP_TOKEN = "imap_backup_token".freeze
  OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
  REFRESH_TOKEN = "refresh_token".freeze

  subject { described_class.new(**params) }

  let(:params) do
    {
      email: EMAIL,
      token: IMAP_BACKUP_TOKEN
    }
  end

  let(:authorizer) do
    instance_double(Google::Auth::UserAuthorizer)
  end

  let(:imap_backup_token) do
    instance_double(
      Gmail::Authenticator::ImapBackupToken,
      access_token: ACCESS_TOKEN,
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      expiration_time_millis: EXPIRATION_TIME_MILLIS,
      refresh_token: REFRESH_TOKEN,
      valid?: true
    )
  end

  let(:token_store) do
    instance_double(Google::Auth::Stores::InMemoryTokenStore)
  end

  let(:credentials) do
    instance_double(Google::Auth::UserRefreshCredentials, refresh!: true)
  end

  let(:expired) { false }

  before do
    allow(Google::Auth::UserAuthorizer).
      to receive(:new).
        with(
          instance_of(Google::Auth::ClientId),
          GMAIL_READ_SCOPE,
          token_store
        ) { authorizer }
    allow(authorizer).to receive(:get_authorization_url).
      with(base_url: OOB_URI) { AUTHORIZATION_URL }
    allow(authorizer).to receive(:get_credentials).
      with(EMAIL) { credentials }
    allow(authorizer).to receive(:get_credentials_from_code).
      with(user_id: EMAIL, code: CODE, base_url: OOB_URI) { CREDENTIALS }

    allow(Google::Auth::UserRefreshCredentials).
      to receive(:new) { credentials }
    allow(credentials).to receive(:expired?) { expired }

    allow(Google::Auth::Stores::InMemoryTokenStore).
      to receive(:new) { token_store }
    allow(token_store).to receive(:store).
      with(EMAIL, anything) # TODO: use a JSON matcher
    allow(Gmail::Authenticator::ImapBackupToken).
      to receive(:new).
        with(IMAP_BACKUP_TOKEN) { imap_backup_token }
  end

  describe "#initialize" do
    [:email, :token].each do |param|
      context "parameter #{param}" do
        let(:params) { super().dup.reject { |k| k == param } }

        it "is expected" do
          expect { subject }.to raise_error(
            ArgumentError, /missing keyword: :?#{param}/
          )
        end
      end
    end
  end

  describe "#credentials" do
    let!(:result) { subject.credentials }

    it "attempts to get credentials" do
      expect(authorizer).to have_received(:get_credentials)
    end

    it "returns the result" do
      expect(result).to eq(credentials)
    end

    context "when the access_token has expired" do
      let(:expired) { true }

      it "refreshes it" do
        expect(credentials).to have_received(:refresh!)
      end
    end
  end

  describe "#authorization_url" do
    let!(:result) { subject.authorization_url }

    it "requests an authorization URL" do
      expect(authorizer).to have_received(:get_authorization_url)
    end

    it "returns the result" do
      expect(result).to eq(AUTHORIZATION_URL)
    end
  end

  describe "#credentials_from_code" do
    let!(:result) { subject.credentials_from_code(CODE) }

    it "requests credentials" do
      expect(authorizer).to have_received(:get_credentials_from_code)
    end

    it "returns credentials" do
      expect(result).to eq(CREDENTIALS)
    end
  end
end
