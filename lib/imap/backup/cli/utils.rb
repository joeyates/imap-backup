require "thunderbird/local_folder"
require "thunderbird/mailbox"
require "thunderbird/profiles"

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
        A folder called 'imap-backup-' + email is created under 'Local Folders'.
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
        export_mailbox(serializer, folder, profile, force: force)
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

      def export_mailbox(serializer, folder, profile, force: false)
        folder_path = File.dirname(folder.name)
        mailbox_name = File.basename(folder.name)
        local_folder =
          if folder_path == "."
            Thunderbird::LocalFolder.new(profile, "")
          else
            Thunderbird::LocalFolder.new(profile, folder_path)
          end

        mailbox = Thunderbird::Mailbox.new(local_folder, mailbox_name)

        if mailbox.msf_exists?
          if force
            Kernel.puts "Deleting '#{mailbox.msf_path}' as --force option was supplied"
            File.unlink mailbox.msf_path
          else
            Kernel.puts "Skipping export of '#{folder.name}' as '#{mailbox.msf_path}' exists"
            return
          end
        end

        if mailbox.exists?
          if force
            Kernel.puts "Overwriting '#{mailbox.path}' as --force option was supplied"
          else
            Kernel.puts "Skipping export of '#{folder.name}' as '#{mailbox.path}' exists"
            return
          end
        end

        FileUtils.cp serializer.mbox_pathname, mailbox.path
      end
    end
  end
end
