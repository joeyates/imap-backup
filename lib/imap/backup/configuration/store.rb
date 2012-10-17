# encoding: utf-8
require 'rubygems' if RUBY_VERSION < '1.9'
require 'json'

module Imap
  module Backup
    module Configuration
      class Store
        CONFIGURATION_DIRECTORY = File.expand_path('~/.imap-backup')

        attr_reader :data
        attr_reader :path

        def initialize(fail_if_missing = true)
          @path     = CONFIGURATION_DIRECTORY
          @pathname = File.join(@path, 'config.json')
          if File.directory?(@path)
            Imap::Backup::Utils.check_permissions @path, 0700
          end
          if File.exist?(@pathname)
            Imap::Backup::Utils.check_permissions @pathname, 0600
            @data = JSON.parse(File.read(@pathname), :symbolize_names => true)
          else
            if fail_if_missing
              raise ConfigurationNotFound.new("Configuration file '#{@pathname}' not found")
            end
            @data = {:accounts => []}
          end
        end

        def save
          mkdir_private @path
          File.open(@pathname, 'w') { |f| f.write(JSON.pretty_generate(@data)) }
          FileUtils.chmod 0600, @pathname
          @data[:accounts].each do |account|
            mkdir_private account[:local_path]
            account[:folders].each do |f|
              parts = f[:name].split('/')
              path  = account[:local_path].clone
              parts.each do |part|
                path = File.join(path, part)
                mkdir_private path
              end
            end
          end
        end

        private

        def mkdir_private(path)
          if ! File.directory?(path)
            FileUtils.mkdir path
          end
          if Imap::Backup::Utils::stat(path) != 0700
            FileUtils.chmod 0700, path
          end
        end
      end
    end
  end
end

