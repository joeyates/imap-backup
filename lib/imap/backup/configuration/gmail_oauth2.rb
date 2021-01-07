module Imap::Backup
  module Configuration; end

  class Configuration::GMailOAuth2
    BANNER = <<~BANNER
      GMail OAuth2 Setup

      You need to authorize imap_backup to get access to your email.
      To do so, please follow the instructions here:

      https://github.com/joeyates/imap-backup/docs/setting-up-gmail.md

    BANNER

    GMAIL_READ_SCOPE = "https://mail.google.com/"
    OOB_URI = "urn:ietf:wg:oauth:2.0:oob"

    attr_reader :account
    attr_reader :client_id
    attr_reader :client_secret

    def initialize(account)
      @account = account
    end

    def run
      Kernel.system("clear")
      Kernel.puts BANNER
      @client_id = highline.ask("client_id: ")
      @client_secret = highline.ask("client_secret: ")

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

      token = JSON.parse(token_store.load(email))
      token["client_secret"] = client_secret
      token.to_json
    end

    private

    def email
      account[:username]
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
      @token_store ||= Google::Auth::Stores::InMemoryTokenStore.new()
    end

    def authorization_url
      authorizer.get_authorization_url(base_url: OOB_URI)
    end
  end
end
