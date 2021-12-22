require "email/provider/base"

class Email::Provider::Unknown < Email::Provider::Base
  # We don't know how to guess the IMAP server
  def host
  end

  def options
    {port: 993, ssl: {ssl_version: :TLSv1_2}}
  end
end
