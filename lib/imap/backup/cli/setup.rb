class Imap::Backup::CLI::Setup < Thor
  include Thor::Actions

  def initialize
    super([])
  end

  no_commands do
    def run
      Imap::Backup::Setup.new.run
    end
  end
end
