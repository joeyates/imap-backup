require "email/provider/base"

class Email::Provider::GMail < Email::Provider::Base
  def host
    "imap.gmail.com"
  end
end
