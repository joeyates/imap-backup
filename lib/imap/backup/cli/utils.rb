require "imap/backup/thunderbird/mailbox_exporter"

module Imap::Backup
  class CLI::Utils < Thor
    include Thor::Actions
    include CLI::Helpers

    FAKE_EMAIL = "fake@email.com"

    desc "ignore-history EMAIL", "Skip downloading emails up to today for all configured folders"
    def ignore_history(email)
      connection = connection(email)

      connection.local_folders.each do |serializer, folder|
        next if !folder.exist?
        do_ignore_folder_history(folder, serializer)
      end
    end

    desc "export-to-thunderbird EMAIL [OPTIONS]",
      <<~DOC
        [Experimental] Copy backed up emails to Thunderbird.
        A folder called 'imap-backup/EMAIL' is created under 'Local Folders'.
      DOC
    method_option(
      "force",
      type: :boolean,
      banner: "overwrite existing mailboxes",
      aliases: ["-f"]
    )
    method_option(
      "profile",
      type: :string,
      banner: "the name of the Thunderbird profile to copy emails to",
      aliases: ["-p"]
    )
    def export_to_thunderbird(email)
      opts = symbolized(options)
      force = opts.key?(:force) ? opts[:force] : false
      profile_name = opts[:profile]

      connection = connection(email)
      profile = thunderbird_profile(profile_name)

      if !profile
        if profile_name
          raise "Thunderbird profile '#{profile_name}' not found"
        else
          raise "Default Thunderbird profile not found"
        end
      end

      connection.local_folders.each do |serializer, folder|
        Thunderbird::MailboxExporter.new(
          email, serializer, profile, force: force
        ).run
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

      def thunderbird_profile(name = nil)
        if name
          Thunderbird::Profiles.new.profile(name)
        else
          Thunderbird::Profiles.new.default
        end
      end
    end
  end
end
