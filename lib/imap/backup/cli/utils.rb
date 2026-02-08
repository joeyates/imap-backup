require "thor"
require "thunderbird/profiles"

require "imap/backup/account/backup_folders"
require "imap/backup/account/serialized_folders"
require "imap/backup/cli/helpers"
require "imap/backup/logger"
require "imap/backup/serializer"
require "imap/backup/thunderbird/mailbox_exporter"
require "imap/backup/serializer/files/path"

module Imap; end

module Imap::Backup
  class CLI < Thor; end

  # Implements the CLI utility functions
  class CLI::Utils < Thor
    include Thor::Actions
    include CLI::Helpers

    desc(
      "ignore-history EMAIL [OPTIONS]",
      "Skip downloading emails up to today for all configured folders"
    )
    config_option
    erb_configuration_option
    quiet_option
    verbose_option
    # Creates fake downloaded emails so that only the account's future emails
    # will really get backed up
    # @return [void]
    def ignore_history(email)
      Logger.setup_logging options
      config = load_config(**options)
      account = account(config, email)
      locker ||= Account::Locker.new(account: account)

      locker.with_lock do
        ignore_account_history(account)
      end
    end

    desc(
      "export-to-thunderbird EMAIL [OPTIONS]",
      <<~DOC
        Copy backed up emails to Thunderbird.
        A folder called 'imap-backup/EMAIL' is created under 'Local Folders'.
      DOC
    )
    config_option
    erb_configuration_option
    quiet_option
    verbose_option
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
    # Exports the account's emails to Thunderbird
    # @return [void]
    def export_to_thunderbird(email)
      Imap::Backup::Logger.setup_logging options
      force = options.key?(:force) ? options[:force] : false
      profile_name = options[:profile]

      config = load_config(**options)
      account = account(config, email)
      profile = thunderbird_profile(profile_name)

      if !profile
        raise "Thunderbird profile '#{profile_name}' not found" if profile_name

        raise "Default Thunderbird profile not found"
      end

      serialized_folders = Account::SerializedFolders.new(account: account)

      raise "No serialized folders were found for account '#{email}'" if serialized_folders.none?

      serialized_folders.each_key do |serializer|
        Thunderbird::MailboxExporter.new(
          email, serializer, profile, force: force
        ).run
      end
    end

    private

    FAKE_EMAIL = "fake@email.com".freeze
    private_constant :FAKE_EMAIL

    def ignore_account_history(account)
      backup_folders = Account::BackupFolders.new(
        client: account.client, account: account
      )
      backup_folders.each do |folder|
        next if !folder.exist?

        path = Serializer::Files::Path.new(
          base_path: account.local_path, folder_name: folder.name
        )
        serializer = Serializer.new(files_path: path)
        ignore_folder_history(folder, serializer)
      end
    end

    def ignore_folder_history(folder, serializer)
      uids = folder.uids - serializer.uids
      Logger.logger.info "Folder '#{folder.name}' - #{uids.length} messages"

      serializer.apply_uid_validity(folder.uid_validity)

      uids.each do |uid|
        message = <<~MESSAGE
          From: #{FAKE_EMAIL}
          Subject: Message #{uid} not backed up
          Skipped #{uid}
        MESSAGE

        serializer.append uid, message, []
      end
    end

    def thunderbird_profile(name = nil)
      profiles = ::Thunderbird::Profiles.new
      if name
        profiles.profile(name)
      else
        if profiles.installs.count > 1
          raise <<~MESSAGE
            Thunderbird has multiple installs, so no default profile exists.
            Please supply a profile name
          MESSAGE
        end

        profiles.installs[0].default_profile
      end
    end
  end
end
