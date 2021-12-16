require "email/provider/default"

class Email::Provider::AppleMail < Email::Provider::Default
  def host
    "imap.mail.me.com"
  end
end
