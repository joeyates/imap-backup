require "thunderbird/local_folder"
require "thunderbird/profiles"

module Imap::Backup
  class Thunderbird::MailboxExporter
    EXPORT_PREFIX = "imap-backup".freeze

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
      return false if !local_folder_ok

      skip_for_msf = check_msf
      return false if skip_for_msf

      skip_for_local_folder = check_local_folder
      return false if skip_for_local_folder

      copy_messages

      true
    end

    private

    def check_local_folder
      return false if !local_folder.exists?

      if force
        Kernel.puts "Overwriting '#{local_folder.path}' as --force option was supplied"
        return false
      end

      Kernel.puts "Skipping export of '#{serializer.folder}' as '#{local_folder.path}' exists"
      true
    end

    def check_msf
      return false if !local_folder.msf_exists?

      if force
        Kernel.puts "Deleting '#{local_folder.msf_path}' as --force option was supplied"
        File.unlink local_folder.msf_path
        return false
      end

      Kernel.puts(
        "Skipping export of '#{serializer.folder}' " \
        "as '#{local_folder.msf_path}' exists"
      )
      true
    end

    def copy_messages
      File.open(local_folder.full_path, "w") do |f|
        enumerator = Serializer::MboxEnumerator.new(serializer.mbox_pathname)
        enumerator.each do |raw|
          clean = Email::Mboxrd::Message.clean_serialized(raw)
          timestamp = Time.now.strftime("%a %b %d %H:%M:%S %Y")
          thunderbird_fom_line = "From - #{timestamp}"
          output = "#{thunderbird_fom_line}\n#{clean}\n"
          f.write output
        end
      end
    end

    def local_folder
      @local_folder ||= begin
        top_level_folders = [EXPORT_PREFIX, email]
        prefixed_folder_path = File.join(top_level_folders, serializer.folder)
        Thunderbird::LocalFolder.new(profile, prefixed_folder_path)
      end
    end
  end
end
