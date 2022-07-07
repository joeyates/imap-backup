require "email/provider/base"

class Email::Provider::AppleMail < Email::Provider::Base
  def host
    "imap.mail.me.com"
  end

  def sets_seen_flags_on_fetch?
    true
  end
end
