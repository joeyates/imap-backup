require_relative "20_test_email_server"

module EmailServerHelpers
  def test_server_connection_parameters
    {
      server: ENV.fetch("DOCKER_HOST_IMAP", "localhost"),
      username: "address@example.com",
      password: "pass",
      local_path: File.join(File.expand_path("~/.imap-backup"), "address_example.com"),
      connection_options: {
        port: ENV.fetch("DOCKER_PORT_IMAP", "8993").to_i,
        ssl: {verify_mode: 0}
      }
    }
  end

  def other_server_connection_parameters
    {
      server: ENV.fetch("DOCKER_HOST_OTHER_IMAP", "localhost"),
      username: "email@other.org",
      password: "pass",
      local_path: File.join(File.expand_path("~/.imap-backup"), "email_other.org"),
      connection_options: {
        port: ENV.fetch("DOCKER_PORT_OTHER_IMAP", "9993").to_i,
        ssl: {verify_mode: 0}
      }
    }
  end

  def test_server
    @test_server ||= TestEmailServer.new(**test_server_connection_parameters)
  end

  def other_server
    @other_server ||= TestEmailServer.new(**other_server_connection_parameters)
  end
end
