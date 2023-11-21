require "thunderbird/local_folder"

require "imap/backup/logger"

module Imap; end

module Imap::Backup
  class Thunderbird; end

  # Exports an account's emails to Thunderbird
  class Thunderbird::MailboxExporter
    def initialize(email, serializer, profile, force: false)
      @email = email
      @serializer = serializer
      @profile = profile
      @force = force
    end

    # Copies the account's messages to the Thunderbird directory
    # in the format expected by Thunderbird
    def run
      if !profile_set_up
        error "The Thunderbird profile '#{profile.title}' " \
              "has not been set up. " \
              "Please set it up before trying to export"
        return false
      end

      local_folder_ok = local_folder.set_up
      if !local_folder_ok
        error "Failed to set up local folder"
        return false
      end

      skip_for_msf = check_msf
      return false if skip_for_msf

      skip_for_local_folder = check_local_folder
      return false if skip_for_local_folder

      info "Exporting account '#{email}' to folder '#{local_folder.full_path}'"
      copy_messages

      true
    end

    private

    EXPORT_PREFIX = "imap-backup".freeze

    attr_reader :email
    attr_reader :serializer
    attr_reader :profile
    attr_reader :force

    def profile_set_up
      File.exist?(profile.local_folders_path)
    end

    def check_local_folder
      return false if !local_folder.exists?

      if force
        info "Overwriting '#{local_folder.path}' as --force option was supplied"
        return false
      end

      warning "Skipping export of '#{serializer.folder}' as '#{local_folder.full_path}' exists"
      true
    end

    def check_msf
      return false if !local_folder.msf_exists?

      if force
        info "Deleting '#{local_folder.msf_path}' as --force option was supplied"
        FileUtils.rm local_folder.msf_path
        return false
      end

      warning(
        "Skipping export of '#{serializer.folder}' " \
        "as '#{local_folder.msf_path}' exists"
      )
      true
    end

    def copy_messages
      File.open(local_folder.full_path, "w") do |f|
        serializer.messages.each do |message|
          timestamp = Time.now.strftime("%a %b %d %H:%M:%S %Y")
          thunderbird_from_line = "From - #{timestamp}"
          output = "#{thunderbird_from_line}\n#{message.body}\n"
          f.write output
        end
      end
    end

    def local_folder
      @local_folder ||= begin
        top_level_folders = [EXPORT_PREFIX, email]
        prefixed_folder_path = File.join(top_level_folders, serializer.folder)
        ::Thunderbird::LocalFolder.new(profile, prefixed_folder_path)
      end
    end

    def error(message)
      Logger.logger.error("[Thunderbird::MailboxExporter] #{message}")
    end

    def info(message)
      Logger.logger.info("[Thunderbird::MailboxExporter] #{message}")
    end

    def warning(message)
      Logger.logger.warn("[Thunderbird::MailboxExporter] #{message}")
    end
  end
end
