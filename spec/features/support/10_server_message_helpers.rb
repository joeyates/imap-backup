module ServerMessageHelpers
  BODY_ATTRIBUTE = "BODY[]".freeze

  def message_as_server_message(from:, subject:, body:, **_options)
    <<~MESSAGE.gsub("\n", "\r\n")
      From: #{from}
      Subject: #{subject}

      #{body}

    MESSAGE
  end

  def server_message_to_body(message)
    message[BODY_ATTRIBUTE]
  end
end
