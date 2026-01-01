require "sys/proctable"
require "json"

module Imap; end

module Imap::Backup
  class Lockfile
    # An error that is thrown if a lockfile already exists
    class LockfileExistsError < StandardError; end

    attr_reader :path

    # Initializes a new Lockfile instance.
    # @param path [String] the path to the lockfile
    def initialize(path:)
      @path = path
    end

    # Creates the lockfile, yields to the given block
    # and ensures the lockfile is removed afterwards.
    def with_lock(&block)
      raise LockfileExistsError, "Lockfile already exists at #{path}" if exists?

      begin
        create
        block.call
      ensure
        remove
      end
    end

    # Checks if the lockfile exists.
    # @return [Boolean] true if the lockfile exists, false otherwise
    def exists?
      File.exist?(path)
    end

    # Removes the lockfile.
    def remove
      FileUtils.rm_f(path)
    end

    # Checks if the lockfile is stale (i.e., the process that created it is no longer running).
    # @return [Boolean] true if the lockfile is stale, false otherwise
    def stale?
      return false if !exists?

      file_content = File.read(path)
      data = JSON.parse(file_content, symbolize_names: true)
      pid = data[:pid]
      starttime = data[:starttime]
      proc_table_entry = Sys::ProcTable.ps(pid: pid)

      return true if proc_table_entry.nil?

      proc_table_entry.starttime != starttime
    end

    private

    def create
      pid = Process.pid
      proc_table_entry = Sys::ProcTable.ps(pid: pid)

      raise "Unable to get process info for PID #{pid}" if proc_table_entry.nil?

      starttime = proc_table_entry.starttime

      data = {
        pid: pid,
        starttime: starttime
      }

      json_data = JSON.generate(data)
      File.write(path, json_data)
    end
  end
end
