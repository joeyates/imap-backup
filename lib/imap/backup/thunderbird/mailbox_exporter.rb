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

      File.open(local_folder.full_path, "w") do |f|
        enumerator = Serializer::MboxEnumerator.new(serializer.mbox_pathname)
        enumerator.each.with_index do |raw, i|
          clean = Email::Mboxrd::Message.clean_serialized(raw)
          timestamp = Time.now.strftime("%a %b %d %H:%M:%S %Y")
          thunderbird_fom_line = "From - #{timestamp}"
          output = "#{thunderbird_fom_line}\n#{clean}\n"
          f.write output
        end
      end

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
