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
          @config = Imap::Backup::Configuration::Store.new
        end

        def run
          loop do
            self.class.highline.choose do |menu|
              menu.header = 'Choose an action'
              @config.data[:accounts].each do |account|
                menu.choice("#{account[:username]}") do
                  edit_account account[:username]
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
          Account.new(@config, account).run
        end
      end
    end
  end
end

