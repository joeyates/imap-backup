require "email/provider/default"

class Email::Provider::Fastmail < Email::Provider::Default
  def host
    "imap.fastmail.com"
  end
end
