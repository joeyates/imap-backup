require "thunderbird/local_folder"
require "thunderbird/mailbox"
require "thunderbird/profiles"

module Imap::Backup
  class Thunderbird::MailboxExporter
    EXPORT_PREFIX = "imap-backup"

    attr_reader :email
    attr_reader :serializer
    attr_reader :profile
    attr_reader :force

    def initialize(email, serializer, profile, force: false)
      @email = email
      @serializer = serializer
      @profile = profile
      @force = force
    end

    def run
      local_folder.set_up

      if mailbox.msf_exists?
        if force
          Kernel.puts "Deleting '#{mailbox.msf_path}' as --force option was supplied"
          File.unlink mailbox.msf_path
        else
          Kernel.puts "Skipping export of '#{folder.name}' as '#{mailbox.msf_path}' exists"
          return false
        end
      end

      if mailbox.exists?
        if force
          Kernel.puts "Overwriting '#{mailbox.path}' as --force option was supplied"
        else
          Kernel.puts "Skipping export of '#{folder.name}' as '#{mailbox.path}' exists"
          return false
        end
      end

      FileUtils.cp serializer.mbox_pathname, mailbox.path

      true
    end

    private

    def local_folder
      @local_folder ||= begin
        folder_path = File.dirname(serializer.folder)
        top_level_folders = [EXPORT_PREFIX, email]
        prefixed_folder_path =
          if folder_path == "."
            File.join(top_level_folders)
          else
            File.join(top_level_folders, folder_path)
          end
        Thunderbird::LocalFolder.new(profile, prefixed_folder_path)
      end
    end

    def mailbox
      @mailbox ||= begin
        mailbox_name = File.basename(serializer.folder)
        Thunderbird::Mailbox.new(local_folder, mailbox_name)
      end
    end
  end
end
