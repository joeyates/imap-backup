require "email/provider/default"

class Email::Provider::GMail < Email::Provider::Default
  def host
    "imap.gmail.com"
  end
end
