module Imap::Backup
  class CLI::Local < Thor
    include Thor::Actions
    include CLI::Helpers

    MAX_SUBJECT = 60

    desc "accounts", "List locally backed-up accounts"
    config_option
    format_option
    def accounts
      config = load_config(**options)
      names = config.accounts.map(&:username)
      case options[:format]
      when "json"
        list = names.map { |n| {username: n} }
        Kernel.puts list.to_json
      else
        names.each { |n| Kernel.puts n }
      end
    end

    desc "folders EMAIL", "List backed up folders"
    config_option
    def folders(email)
      config = load_config(**options)
      connection = connection(config, email)

      connection.local_folders.each do |_s, f|
        Kernel.puts %("#{f.name}")
      end
    end

    desc "list EMAIL FOLDER", "List emails in a folder"
    config_option
    def list(email, folder_name)
      config = load_config(**options)
      connection = connection(config, email)

      folder_serializer, _folder = connection.local_folders.find do |(_s, f)|
        f.name == folder_name
      end
      raise "Folder '#{folder_name}' not found" if !folder_serializer

      Kernel.puts format(
        "%-10<uid>s  %-#{MAX_SUBJECT}<subject>s - %<date>s",
        {uid: "UID", subject: "Subject", date: "Date"}
      )
      Kernel.puts "-" * (12 + MAX_SUBJECT + 28)

      uids = folder_serializer.uids

      folder_serializer.each_message(uids).map do |message|
        list_message message
      end
    end

    desc "show EMAIL FOLDER UID[,UID]", "Show one or more emails"
    long_desc <<~DESC
      Prints out the requested emails.
      If more than one UID is given, they are separated by a header indicating
      the UID.
    DESC
    config_option
    def show(email, folder_name, uids)
      config = load_config(**options)
      connection = connection(config, email)

      folder_serializer, _folder = connection.local_folders.find do |(_s, f)|
        f.name == folder_name
      end
      raise "Folder '#{folder_name}' not found" if !folder_serializer

      uid_list = uids.split(",")
      folder_serializer.each_message(uid_list).each do |message|
        if uid_list.count > 1
          Kernel.puts <<~HEADER
            #{'-' * 80}
            #{format('| UID: %-71s |', message.uid)}
            #{'-' * 80}
          HEADER
        end
        Kernel.puts message.body
      end
    end

    no_commands do
      def list_message(message)
        m = {
          uid: message.uid,
          date: message.date.to_s,
          subject: message.subject || ""
        }
        if m[:subject].length > MAX_SUBJECT
          Kernel.puts format("% 10<uid>u: %.#{MAX_SUBJECT - 3}<subject>s... - %<date>s", m)
        else
          Kernel.puts format("% 10<uid>u: %-#{MAX_SUBJECT}<subject>s - %<date>s", m)
        end
      end
    end
  end
end
