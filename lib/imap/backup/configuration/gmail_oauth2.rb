module Imap::Backup
  module Configuration; end

  class Configuration::GmailOauth2
    BANNER = <<~BANNER.freeze
      GMail OAuth2 Setup

      You need to authorize imap_backup to get access to your email.
      To do so, please follow the instructions here:

      https://github.com/joeyates/imap-backup/blob/main/docs/setting-up-gmail.md

    BANNER

    GMAIL_READ_SCOPE = "https://mail.google.com/".freeze
    OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze

    attr_reader :account
    attr_reader :client_id
    attr_reader :client_secret

    def initialize(account)
      @account = account
    end

    def run
      Kernel.system("clear")
      Kernel.puts BANNER

      keep = if token.valid?
        highline.agree("Use existing client info?")
      else
        false
      end

      if keep
        @client_id = token.client_id
        @client_secret = token.client_secret
      else
        @client_id = highline.ask("client_id: ")
        @client_secret = highline.ask("client_secret: ")
      end

      Kernel.puts <<~MESSAGE

        Open the following URL in your browser

        #{authorization_url}

        Then copy the success code

      MESSAGE

      @code = highline.ask("success code: ")
      @credentials = authorizer.get_and_store_credentials_from_code(
        user_id: email, code: @code, base_url: OOB_URI
      )

      raise "Failed" if !@credentials

      new_token = JSON.parse(token_store.load(email))
      new_token["client_secret"] = client_secret
      new_token.to_json
    end

    private

    def email
      account[:username]
    end

    def password
      account[:password]
    end

    def token
      @token ||= Gmail::Authenticator::ImapBackupToken.new(password)
    end

    def highline
      Configuration::Setup.highline
    end

    def auth_client_id
      @auth_client_id = Google::Auth::ClientId.new(client_id, client_secret)
    end

    def authorizer
      @authorizer ||= Google::Auth::UserAuthorizer.new(
        auth_client_id, GMAIL_READ_SCOPE, token_store
      )
    end

    def token_store
      @token_store ||= Google::Auth::Stores::InMemoryTokenStore.new
    end

    def authorization_url
      authorizer.get_authorization_url(base_url: OOB_URI)
    end
  end
end
