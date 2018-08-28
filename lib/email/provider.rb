module Email; end

class Email::Provider
  def self.for_address(address)
    case
    when address.end_with?("@fastmail.com")
      new(:fastmail)
    when address.end_with?("@gmail.com")
      new(:gmail)
    when address.end_with?("@fastmail.fm")
      new(:fastmail)
    else
      new(:default)
    end
  end

  attr_reader :provider

  def initialize(provider)
    @provider = provider
  end

  def options
    case provider
    when :gmail
      {port: 993, ssl: true}
    when :fastmail
      {port: 993, ssl: true}
    else
      {port: 993, ssl: true}
    end
  end

  def host
    case provider
    when :gmail
      "imap.gmail.com"
    when :fastmail
      "imap.fastmail.com"
    end
  end
end
