# encoding: utf-8
require 'rubygems' if RUBY_VERSION < '1.9'
require 'highline'

module Imap
  module Backup
    module Configuration

      class Setup
        class << self
          attr_accessor :highline
        end
        self.highline = HighLine.new

        def initialize
          @config = Imap::Backup::Configuration::Store.new(false)
        end

        def run
          loop do
            self.class.highline.choose do |menu|
              menu.header = 'Choose an action'
              @config.data[:accounts].each do |account|
                menu.choice("#{account[:username]}") do
                  Account.new(@config, account[:username]).run
                end
              end
              menu.choice('add account') do
                username = Asker.email
                edit_account username
              end
              menu.choice('save and exit') do
                @config.save
                return
              end
              menu.choice(:quit) do
                return
              end
            end
          end
        end

        private

        def add_account(username)
          account = {
            :username   => username,
            :password   => '',
            :local_path => File.join(@config.path, username.gsub('@', '_')),
            :folders    => []
          }
          @config.data[:accounts] << account
          account
        end

        def edit_account(username)
          account = @config.data[:accounts].find { |a| a[:username] == username }
          if account.nil?
            account = add_account(username)
          end
          Account.new @config, account[:username]
        end

      end

      module Asker

        EMAIL_MATCHER = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i

        def self.email(default = '')
          Setup.highline.ask('email address: ') do |q|
            q.default               = default
            q.readline              = true
            q.validate              = EMAIL_MATCHER
            q.responses[:not_valid] = 'Enter a valid email address '
          end
        end

        def self.password
          password     = Setup.highline.ask('password: ')        { |q| q.echo = false }
          confirmation = Setup.highline.ask('repeat password: ') { |q| q.echo = false }
          if password != confirmation
            return nil unless Setup.highline.agree("the password and confirmation did not match.\nContinue? (y/n) ")
            return self.password
          end
          password
        end

        def self.backup_path(default, validator)
          Setup.highline.ask('backup directory: ') do |q|
            q.default  = default
            q.readline = true
            q.validate = validator
            q.responses[:not_valid] = 'Choose a different directory '
          end
        end

      end

      module ConnectionTester
        def self.test(account)
          Imap::Backup::Account::Connection.new(account)
          return 'Connection successful'
        rescue Net::IMAP::NoResponseError
          return 'No response'
        rescue Exception => e
          return "Unexpected error: #{e}"
        end
      end

      class FolderChooser
        def initialize(account)
          @account = account
        end

        def run
          begin
            @connection = Imap::Backup::Account::Connection.new(@account)
          rescue => e
            puts 'Connection failed'
            Setup.highline.ask 'Press a key '
            return
          end
          @folders = @connection.folders
          loop do
            Setup.highline.choose do |menu|
              menu.header = 'Add/remove folders'
              menu.index = :number
              @folders.each do |folder|
                name  = folder.name
                found = @account[:folders].find { |f| f[:name] == name }
                mark  =
                  if found
                    '+'
                  else
                    '-'
                  end
                menu.choice("#{mark} #{name}") do
                  if found
                    @account[:folders].reject! { |f| f[:name] == name }
                  else
                    @account[:folders] << { :name => name }
                  end
                end
              end
              menu.choice('return to the account menu') do
                return
              end
              menu.hidden('quit') do
                return
              end
            end
          end
        end
      end

      class Account

        def initialize(store, account)
          @store, @account = store, account
        end

        def run
          loop do
            Setup.highline.choose do |menu|
              password =
                if @account[:password] == ''
                 '(unset)'
                else
                  @account[:password].gsub(/./, 'x')
                end
              menu.header = <<EOT
Account:
  email:    #{@account[:username]}
  path:     #{@account[:local_path]}
  folders:  #{@account[:folders].map { |f| f[:name] }.join(', ')}
  password: #{password}
EOT
              menu.choice('modify email') do
                username = Asker.email(username)
                others   = @store.data[:accounts].select { |a| a != @account}.map { |a| a[:username] }
                if others.include?(username)
                  puts 'There is already an account set up with that email address'
                else
                  @account[:username] = username
                end
              end
              menu.choice('modify password') do
                password = Asker.password
                if ! password.nil?
                  @account[:password] = password
                end
              end
              menu.choice('modify backup path') do
                validator = lambda do |p|
                  same = @store.data[:accounts].find do |a|
                    a[:username] != @account[:username] && a[:local_path] == p
                  end
                  if same
                    puts "The path '#{p}' is used to backup the account '#{same[:username]}'"
                    false
                  else
                    true
                  end
                end
                @account[:local_path] = Asker.backup_path(@account[:local_path], validator)
              end
              menu.choice('choose backup folders') do
                FolderChooser.new(@account).run
              end
              menu.choice 'test authentication' do
                result = ConnectionTester.test(@account)
                puts result 
                Setup.highline.ask 'Press a key '
              end
              menu.choice(:delete) do
                if Setup.highline.agree("Are you sure? (y/n) ")
                  @store.data[:accounts].reject! { |a| a[:username] == @account[:username] }
                  return
                end
              end
              menu.choice('return to main menu') do
                return
              end
              menu.hidden('quit') do
                return
              end
            end
          end
        end

      end
    end
  end
end

