module Email; end
class Email::Provider; end

class Email::Provider::Base
  def options
    # rubocop:disable Naming/VariableNumber
    {port: 993, ssl: {ssl_version: :TLSv1_2}}
    # rubocop:enable Naming/VariableNumber
  end
end
