module Imap::Backup
  class MultiFetchFailedError < StandardError; end

  class Downloader
    attr_reader :folder
    attr_reader :serializer
    attr_reader :multi_fetch_size

    def initialize(folder, serializer, multi_fetch_size: 1)
      @folder = folder
      @serializer = serializer
      @multi_fetch_size = multi_fetch_size
      @uids = nil
    end

    def run
      debug "#{uids.count} new messages"

      uids.each_slice(multi_fetch_size).with_index do |block, i|
        multifetch_failed = download_block(block, i)
        raise MultiFetchFailedError if multifetch_failed
      end
    rescue MultiFetchFailedError
      @count = nil
      @multi_fetch_size = 1
      @uids = nil
      retry
    end

    private

    def download_block(block, index)
      uids_and_bodies = folder.fetch_multi(block)
      if uids_and_bodies.nil?
        if multi_fetch_size > 1
          uids = block.join(", ")
          debug("Multi fetch failed for UIDs #{uids}, switching to single fetches")
          return true
        else
          debug("Fetch failed for UID #{block[0]} - skipping")
          return false
        end
      end

      offset = (index * multi_fetch_size) + 1
      uids_and_bodies.each.with_index do |uid_and_body, j|
        handle_uid_and_body uid_and_body, offset + j
      end

      false
    end

    def handle_uid_and_body(uid_and_body, index)
      uid = uid_and_body[:uid]
      body = uid_and_body[:body]
      case
      when !body
        info("Fetch returned empty body - skipping")
      when !uid
        info("Fetch returned empty UID - skipping")
      else
        debug("uid: #{uid} (#{index}/#{uids.count}) - #{body.size} bytes")
        serializer.append uid, body
      end
    end

    def uids
      @uids ||= folder.uids - serializer.uids
    end

    def info(message)
      Logger.logger.info("[#{folder.name}] #{message}")
    end

    def debug(message)
      Logger.logger.debug("[#{folder.name}] #{message}")
    end
  end
end
