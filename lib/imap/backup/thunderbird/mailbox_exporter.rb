require "thunderbird/local_folder"
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
      local_folder_ok = local_folder.set_up
      return if !local_folder_ok

      if local_folder.msf_exists?
        if force
          Kernel.puts "Deleting '#{local_folder.msf_path}' as --force option was supplied"
          File.unlink local_folder.msf_path
        else
          Kernel.puts "Skipping export of '#{serializer.folder}' as '#{local_folder.msf_path}' exists"
          return false
        end
      end

      if local_folder.exists?
        if force
          Kernel.puts "Overwriting '#{local_folder.path}' as --force option was supplied"
        else
          Kernel.puts "Skipping export of '#{serializer.folder}' as '#{local_folder.path}' exists"
          return false
        end
      end

      FileUtils.cp serializer.mbox_pathname, local_folder.full_path

      true
    end

    private

    def local_folder
      @local_folder ||= begin
        top_level_folders = [EXPORT_PREFIX, email]
        prefixed_folder_path = File.join(top_level_folders, serializer.folder)
        Thunderbird::LocalFolder.new(profile, prefixed_folder_path)
      end
    end
  end
end
