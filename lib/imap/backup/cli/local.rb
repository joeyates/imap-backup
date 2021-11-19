module Imap::Backup
  class CLI::Local < Thor
    include Thor::Actions
    include CLI::Helpers

    desc "accounts", "List locally backed-up accounts"
    def accounts
      connections = Imap::Backup::Configuration::List.new
      connections.accounts.each { |a| puts a[:username] }
    end

    desc "folders EMAIL", "List account folders"
    def folders(email)
      connections = Imap::Backup::Configuration::List.new
      account = connections.accounts.find { |a| a[:username] == email }
      raise "#{email} is not a configured account" if !account

      account_connection = Imap::Backup::Account::Connection.new(account)
      account_connection.local_folders.each do |_s, f|
        puts %("#{f.name}")
      end
    end

    desc "emails EMAIL FOLDER", "List emails in a folder"
    def emails(email, folder_name)
      connections = Imap::Backup::Configuration::List.new
      account = connections.accounts.find { |a| a[:username] == email }
      raise "#{email} is not a configured account" if !account

      account_connection = Imap::Backup::Account::Connection.new(account)
      folder_serializer, folder = account_connection.local_folders.find do |(_s, f)|
        f.name == folder_name
      end
      raise "Folder '#{folder_name}' not found" if !folder_serializer

      max_subject = 60
      puts format("%-10<uid>s  %-#{max_subject}<subject>s - %<date>s", {uid: "UID", subject: "Subject", date: "Date"})
      puts "-" * (12 + max_subject + 28)

      uids = folder_serializer.uids

      folder_serializer.each_message(uids).map do |uid, message|
        m = {
          uid: uid,
          date: message.parsed.date.to_s,
          subject: message.parsed.subject
        }
        if m[:subject].length > max_subject
          puts format("% 10<uid>u: %.#{max_subject - 3}<subject>s... - %<date>s", m)
        else
          puts format("% 10<uid>u: %-#{max_subject}<subject>s - %<date>s", m)
        end
      end
    end

    desc "email EMAIL FOLDER UID", "Show an email"
    def email(email, folder_name, uid)
      connections = Imap::Backup::Configuration::List.new
      account = connections.accounts.find { |a| a[:username] == email }
      raise "#{email} is not a configured account" if !account

      account_connection = Imap::Backup::Account::Connection.new(account)
      folder_serializer, _folder = account_connection.local_folders.find do |(_s, f)|
        f.name == folder_name
      end
      raise "Folder '#{folder_name}' not found" if !folder_serializer

      loaded_message = folder_serializer.load(uid)
      raise "Message #{uid} not found in folder '#{folder_name}'" if !loaded_message

      puts loaded_message.supplied_body
    end
  end
end
