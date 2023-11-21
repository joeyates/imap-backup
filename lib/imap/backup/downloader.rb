require "net/imap"

module Imap; end

module Imap::Backup
  # Downloads as yet undownloaded emails from an account's server
  class Downloader
    # @private
    class MultiFetchFailedError < StandardError; end

    def initialize(folder, serializer, multi_fetch_size: 1, reset_seen_flags_after_fetch: false)
      @folder = folder
      @serializer = serializer
      @multi_fetch_size = multi_fetch_size
      @reset_seen_flags_after_fetch = reset_seen_flags_after_fetch
      @uids = nil
    end

    # Runs the downloader
    def run
      info("#{uids.count} new messages") if uids.any?

      uids.each_slice(multi_fetch_size).with_index do |block, i|
        multifetch_failed = download_block(block, i)
        raise MultiFetchFailedError if multifetch_failed
      end
    rescue MultiFetchFailedError
      @count = nil
      @multi_fetch_size = 1
      @uids = nil
      retry
    rescue Net::IMAP::ByeResponseError
      folder.client.reconnect
      retry
    end

    private

    attr_reader :folder
    attr_reader :serializer
    attr_reader :multi_fetch_size
    attr_reader :reset_seen_flags_after_fetch

    def download_block(block, index)
      uids_and_bodies =
        if reset_seen_flags_after_fetch
          before_unseen = folder.unseen(block)
          debug "Pre-fetch unseen messages: #{before_unseen.join(', ')}"
          uids_and_bodies = folder.fetch_multi(block)
          after_unseen = folder.unseen(block)
          debug "Post-fetch unseen messages: #{after_unseen.join(', ')}"
          changed = before_unseen - after_unseen
          if changed.any?
            ids = changed.join(", ")
            debug "Removing '\Seen' flag for the following messages: #{ids}"
            folder.remove_flags(changed, [:Seen])
          end
          uids_and_bodies
        else
          folder.fetch_multi(block)
        end
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
      flags = uid_and_body[:flags]
      case
      when !body
        info("Fetch returned empty body - skipping")
      when !uid
        info("Fetch returned empty UID - skipping")
      else
        debug("uid: #{uid} (#{index}/#{uids.count}) - #{body.size} bytes")
        serializer.append uid, body, flags
      end
    rescue StandardError => e
      error(e)
    end

    def uids
      @uids ||= folder.uids - serializer.uids
    end

    def debug(message)
      Logger.logger.debug("[#{folder.name}] #{message}")
    end

    def error(message)
      Logger.logger.error("[#{folder.name}] #{message}")
    end

    def info(message)
      Logger.logger.info("[#{folder.name}] #{message}")
    end
  end
end
