module Imap::Backup
  class CLI::Local < Thor
    include Thor::Actions
    include CLI::Helpers

    desc "accounts", "List locally backed-up accounts"
    def accounts
      connections = Imap::Backup::Configuration::List.new
      connections.accounts.each { |a| Kernel.puts a.username }
    end

    desc "folders EMAIL", "List account folders"
    def folders(email)
      connection = connection(email)

      connection.local_folders.each do |_s, f|
        Kernel.puts %("#{f.name}")
      end
    end

    desc "list EMAIL FOLDER", "List emails in a folder"
    def list(email, folder_name)
      connection = connection(email)

      folder_serializer, _folder = connection.local_folders.find do |(_s, f)|
        f.name == folder_name
      end
      raise "Folder '#{folder_name}' not found" if !folder_serializer

      max_subject = 60
      Kernel.puts format(
        "%-10<uid>s  %-#{max_subject}<subject>s - %<date>s",
        {uid: "UID", subject: "Subject", date: "Date"}
      )
      Kernel.puts "-" * (12 + max_subject + 28)

      uids = folder_serializer.uids

      folder_serializer.each_message(uids).map do |uid, message|
        m = {
          uid: uid,
          date: message.date.to_s,
          subject: message.subject || ""
        }
        if m[:subject].length > max_subject
          Kernel.puts format("% 10<uid>u: %.#{max_subject - 3}<subject>s... - %<date>s", m)
        else
          Kernel.puts format("% 10<uid>u: %-#{max_subject}<subject>s - %<date>s", m)
        end
      end
    end

    desc "show EMAIL FOLDER UID[,UID]", "Show one or more emails"
    long_desc <<~DESC
      Prints out the requested emails.
      If more than one UID is given, they are separated by a header indicating
      the UID.
    DESC
    def show(email, folder_name, uids)
      connection = connection(email)

      folder_serializer, _folder = connection.local_folders.find do |(_s, f)|
        f.name == folder_name
      end
      raise "Folder '#{folder_name}' not found" if !folder_serializer

      uid_list = uids.split(",")
      folder_serializer.each_message(uid_list).each do |uid, message|
        if uid_list.count > 1
          Kernel.puts <<~HEADER
            #{'-' * 80}
            #{format('| UID: %-71s |', uid)}
            #{'-' * 80}
          HEADER
        end
        Kernel.puts message.supplied_body
      end
    end
  end
end
