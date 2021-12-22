module Email; end
class Email::Provider; end

class Email::Provider::Base
  def options
    {port: 993, ssl: {ssl_version: :TLSv1_2}}
  end
end
