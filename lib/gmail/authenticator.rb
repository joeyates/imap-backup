require "googleauth"
require "google/auth/stores/in_memory_token_store"

module Gmail; end

class Gmail::Authenticator
  class MalformedImapBackupToken < StandardError; end

  class ImapBackupToken
    attr_reader :token

    def self.from(
      access_token:,
      client_id:,
      client_secret:,
      expiration_time_millis:,
      refresh_token:
    )
      {
        access_token: access_token,
        client_id: client_id,
        client_secret: client_secret,
        expiration_time_millis: expiration_time_millis,
        refresh_token: refresh_token
      }.to_json
    end

    def initialize(token)
      @token = token
    end

    def valid?
      return false if !body
      return false if !access_token
      return false if !client_id
      return false if !client_secret
      return false if !expiration_time_millis
      return false if !refresh_token

      true
    end

    def access_token
      body["access_token"]
    end

    def client_id
      body["client_id"]
    end

    def client_secret
      body["client_secret"]
    end

    def expiration_time_millis
      body["expiration_time_millis"]
    end

    def refresh_token
      body["refresh_token"]
    end

    private

    def body
      @body ||= JSON.parse(token)
    rescue JSON::ParserError
      nil
    end
  end

  GMAIL_READ_SCOPE = "https://mail.google.com/".freeze
  OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze

  attr_reader :email
  attr_reader :token

  def self.refresh_token?(text)
    ImapBackupToken.new(text).valid?
  end

  def initialize(email:, token:)
    @email = email
    @token = token
  end

  def authorization_url
    authorizer.get_authorization_url(base_url: OOB_URI)
  end

  def credentials
    authorizer.get_credentials(email).tap do |c|
      c.refresh! if c.expired?
    end
  end

  def credentials_from_code(code)
    authorizer.get_credentials_from_code(
      user_id: email,
      code: code,
      base_url: OOB_URI
    )
  end

  private

  def auth_client_id
    @auth_client_id = Google::Auth::ClientId.new(client_id, client_secret)
  end

  def authorizer
    @authorizer ||= Google::Auth::UserAuthorizer.new(
      auth_client_id, GMAIL_READ_SCOPE, token_store
    )
  end

  def access_token
    imap_backup_token.access_token
  end

  def client_id
    imap_backup_token.client_id
  end

  def client_secret
    imap_backup_token.client_secret
  end

  def expiration_time_millis
    imap_backup_token.expiration_time_millis
  end

  def refresh_token
    imap_backup_token.refresh_token
  end

  def imap_backup_token
    @imap_backup_token ||=
      ImapBackupToken.new(token).tap do |t|
        raise MalformedImapBackupToken if !t.valid?
      end
  end

  def store_token
    {
      "client_id" => client_id,
      "access_token" => access_token,
      "refresh_token" => refresh_token,
      "scope": [GMAIL_READ_SCOPE],
      "expiration_time_millis": expiration_time_millis
    }.to_json
  end

  def token_store
    @token_store ||=
      Google::Auth::Stores::InMemoryTokenStore.new.tap do |t|
        t.store(email, store_token)
      end
  end
end
