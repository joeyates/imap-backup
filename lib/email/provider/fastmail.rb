require "email/provider/base"

class Email::Provider::Fastmail < Email::Provider::Base
  def host
    "imap.fastmail.com"
  end
end
