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
      loop do
        system('clear')
        self.class.highline.choose do |menu|
          menu.header = 'Choose an action'
          config.data[:accounts].each do |account|
            menu.choice("#{account[:username]}") do
              edit_account account[:username]
            end
          end
          menu.choice('add account') do
            username = Configuration::Asker.email
            edit_account username
          end
          menu.choice('save and exit') do
            config.save
            return
          end
          menu.choice(:quit) do
            return
          end
        end
      end
    end

    private

    def config
      @config ||= Configuration::Store.new
    end

    def setup_logging
      Imap::Backup.logger.level =
        if config.data[:debug]
          ::Logger::Severity::DEBUG
        else
          ::Logger::Severity::ERROR
        end
    end

    def add_account(username)
      account = {
        :username   => username,
        :password   => '',
        :local_path => File.join(config.path, username.gsub('@', '_')),
        :folders    => []
      }
      config.data[:accounts] << account
      account
    end

    def edit_account(username)
      account = config.data[:accounts].find { |a| a[:username] == username }
      if account.nil?
        account = add_account(username)
      end
      Configuration::Account.new(config, account, Configuration::Setup.highline).run
    end
  end
end
