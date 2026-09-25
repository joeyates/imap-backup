require "fileutils"
require "securerandom"
require "imap/backup/mirror/map"

module Imap; end

module Imap::Backup
  # Synchronises a folder between a source and destination
  class Mirror
    # @param serializer [Serializer] the source of backed-up messages
    # @param folder [Account::Folder] the destination folder to mirror into
    # @param reset [Boolean] true to delete destination-only messages first
    # @param continue_on_error [Boolean] true to keep processing after append errors
    def initialize(serializer, folder, reset: false, continue_on_error: false)
      @serializer = serializer
      @folder = folder
      @reset = reset
      @continue_on_error = continue_on_error
    end

    # If necessary, creates the destination folder,
    # then deletes any messages in the destination folder
    # that are not in the local store,
    # sets existing messages' flags
    # then appends any missing messages
    # and saves the mapping file
    # @return [void]
    def run
      ensure_destination_folder
      delete_destination_only_emails if reset
      update_flags
      append_emails
      map.save
    end

    private

    CHUNK_SIZE = 100
    private_constant :CHUNK_SIZE

    # When a folder is larger than this, enable periodic progress logging
    LARGE_FOLDER_THRESHOLD = 1000
    PROGRESS_INTERVAL = 100

    attr_reader :serializer
    attr_reader :folder
    attr_reader :reset
    attr_reader :continue_on_error

    def ensure_destination_folder
      return if folder.exist?

      folder.create
    end

    def delete_destination_only_emails
      uids_to_delete = destination_only_emails
      return if uids_to_delete.empty?

      folder.delete_multi(uids_to_delete)
    end

    def destination_only_emails
      source_uids = serializer.uids
      destination_uids = folder.uids
      destination_uids.filter { |uid| !source_uids.include?(map.source_uid(uid)) }
    end

    def update_flags
      folder.uids.each_slice(CHUNK_SIZE) do |uids|
        update_uids(uids)
      end
    end

    def update_uids(uids)
      uids_and_flags = folder.fetch_multi(uids, ["FLAGS"])
      uids_and_flags.each do |uid_and_flags|
        destination_uid = uid_and_flags[:uid]
        flags = uid_and_flags[:flags]
        source_uid = map.source_uid(destination_uid)
        next if !source_uid

        message = serializer.get(source_uid)
        folder.set_flags([destination_uid], message.flags) if flags.sort != message.flags.sort
      end
    end

    def append_emails
      total = serializer.uids&.size || 0
      log_progress = total >= LARGE_FOLDER_THRESHOLD

      processed = 0
      appended = 0
      skipped = 0
      start_time = Time.now

      serializer.each_message do |message|
        processed += 1
        existing = map.destination_uid(message.uid)

        if existing
          skipped += 1
          if log_progress && (processed % PROGRESS_INTERVAL).zero?
            log_progress_status(processed, total, appended, skipped, start_time)
          end
          next
        end

        # Clients cannot set the 'Recent' flag
        message.flags.reject! { |f| f == :Recent }

        begin
          destination_uid = folder.append(message)
          map.map_uids(source: message.uid, destination: destination_uid)
          appended += 1
        rescue StandardError => e
          handle_append_error(message, e)
          raise if !continue_on_error
        end

        if log_progress && (processed % PROGRESS_INTERVAL).zero?
          log_progress_status(processed, total, appended, skipped, start_time)
        end
      end

      if log_progress
        log_progress_status(processed, total, appended, skipped, start_time, final: true)
      end
    end

    def log_progress_status(processed, total, appended, skipped, start_time, final: false)
      elapsed = Time.now - start_time
      avg = processed > 0 ? elapsed / processed : 0
      remaining = total - processed
      eta = remaining > 0 ? Time.at(avg * remaining).utc.strftime("%H:%M:%S") : "00:00:00"
      pct = total > 0 ? ((processed.to_f / total) * 100).round(2) : nil

      msg = if total > 0
              "Folder '#{folder.name}': #{processed}/#{total} (#{pct}%) processed, " \
              "appended=#{appended}, skipped=#{skipped}, elapsed=#{format_duration(elapsed)}, ETA=#{eta}"
            else
              "Folder '#{folder.name}': #{processed} processed, appended=#{appended}, " \
              "skipped=#{skipped}, elapsed=#{format_duration(elapsed)}"
            end

      if final
        Logger.logger.info "Completed: #{msg}"
      else
        Logger.logger.info "Progress: #{msg}"
      end
    end

    def format_duration(seconds)
      return "00:00:00" if seconds.nil? || seconds.zero?
      h = (seconds / 3600).to_i
      m = ((seconds % 3600) / 60).to_i
      s = (seconds % 60).to_i
      format("%02d:%02d:%02d", h, m, s)
    end

    def handle_append_error(message, error)
      file_path = failed_email_path(message, error)
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, message.imap_body)
      Logger.logger.warn(
        "Could not copy message UID #{message.uid} to '#{folder.name}': " \
        "#{error.class}: #{error.message}. Saved failed email to '#{file_path}'"
      )
    end

    def failed_email_path(message, error)
      File.join("/tmp", "imap-backup", safe_error_type(error), failed_email_filename(message))
    end

    def failed_email_filename(message)
      timestamp = Time.now.utc.strftime("%Y%m%dT%H%M%S%LZ")
      subject = sanitize_path_component(message.subject.to_s)
      subject = "untitled" if subject.empty?
      "#{timestamp}_uid#{message.uid}_#{subject}_#{SecureRandom.hex(2)}.eml"
    end

    def safe_error_type(error)
      error.class.name.to_s
        .gsub(/[^A-Za-z0-9._-]+/, "_")
        .gsub(/_+/, "_")
        .gsub(/\A_+|_+\z/, "")
    end

    def sanitize_path_component(value)
      value
        .to_s
        .gsub(/[\/\\:*?\"<>|\r\n]+/, " ")
        .gsub(/[[:cntrl:]]+/, " ")
        .strip
        .gsub(/\s+/, "_")
        .gsub(/_+/, "_")
        .gsub(/\A_+|_+\z/, "")
        .slice(0, 80)
        .gsub(/\A_+|_+\z/, "")
    end

    def map
      @map ||=
        Mirror::Map.new(pathname: map_pathname, destination: destination_email).tap do |map|
          map_ok = map.check_uid_validities(
            source: serializer.uid_validity,
            destination: folder.uid_validity
          )
          if !map_ok
            folder.clear if reset
            map.reset(
              source_uid_validity: serializer.uid_validity,
              destination_uid_validity: folder.uid_validity
            )
          end
        end
    end

    def map_pathname
      "#{serializer.files_path}.mirror"
    end

    def destination_email
      folder.client.username
    end
  end
end
