require_relative "10_server_message_helpers"
require_relative "30_email_server_helpers"

RSpec.configure do |config|
  config.include ServerMessageHelpers, type: :aruba
  config.include EmailServerHelpers, type: :aruba
end
