module Imap::Backup
  class CLI::Utils < Thor
    include Thor::Actions

    FAKE_EMAIL = "fake@email.com"

    desc "ignore-history EMAIL", "Skip downloading emails up to today for all configured folders"
    def ignore_history(email)
      connections = Imap::Backup::Configuration::List.new
      account = connections.accounts.find { |a| a[:username] == email }
      raise "#{email} is not a configured account" if !account

      connection = Imap::Backup::Account::Connection.new(account)

      connection.local_folders.each do |serializer, folder|
        next if !folder.exist?
        do_ignore_folder_history(folder, serializer)
      end
    end

    no_commands do
      def do_ignore_folder_history(folder, serializer)
        uids = folder.uids - serializer.uids
        Imap::Backup.logger.info "Folder '#{folder.name}' - #{uids.length} messages"

        serializer.apply_uid_validity(folder.uid_validity)

        uids.each do |uid|
          message = <<~MESSAGE
            From: #{FAKE_EMAIL}
            Subject: Message #{uid} not backed up
            Skipped #{uid}
          MESSAGE

          serializer.save(uid, message)
        end
      end
    end
  end
end
