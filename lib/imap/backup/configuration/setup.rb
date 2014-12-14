# encoding: utf-8
require 'rubygems' if RUBY_VERSION < '1.9'
require 'highline'

module Imap::Backup
  module Configuration; end

  class Configuration::Setup
    class << self
      attr_accessor :highline
    end
    self.highline = HighLine.new

    def run
      setup_logging
      catch :done do
        loop do
          system('clear')
          show_menu
        end
      end
    end

    private

    def show_menu
      self.class.highline.choose do |menu|
        menu.header = 'Choose an action'
        account_items menu
        add_account_item menu
        menu.choice('save and exit') do
          config.save
          throw :done
        end
        menu.choice('exit without saving changes') do
          throw :done
        end
      end
    end

    def account_items(menu)
      config.accounts.each do |account|
        next if account[:delete]
        item = account[:username].clone
        item << ' *' if account[:modified]
        menu.choice(item) do
          edit_account account[:username]
        end
      end
    end

    def add_account_item(menu)
      menu.choice('add account') do
        username = Configuration::Asker.email
        edit_account username
      end
    end

    def config
      @config ||= Configuration::Store.new
    end

    def setup_logging
      Imap::Backup.logger.level =
        if config.debug?
          ::Logger::Severity::DEBUG
        else
          ::Logger::Severity::ERROR
        end
    end

    def default_account_config(username)
      account = {
        :username   => username,
        :password   => '',
        :local_path => File.join(config.path, username.gsub('@', '_')),
        :folders    => []
      }
    end

    def edit_account(username)
      account = config.accounts.find { |a| a[:username] == username }
      if account.nil?
        account = default_account_config(username)
        config.accounts << account
      end
      Configuration::Account.new(config, account, Configuration::Setup.highline).run
    end
  end
end
