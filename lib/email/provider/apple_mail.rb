require "email/provider/base"

class Email::Provider::AppleMail < Email::Provider::Base
  def host
    "imap.mail.me.com"
  end
end
