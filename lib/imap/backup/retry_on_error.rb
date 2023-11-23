require "imap/backup/logger"

module Imap; end

module Imap::Backup
  # Provides a mechanism for retrying blocks of code which often throw errors
  module RetryOnError
    # Calls the supplied block,
    # traps the given types of errors
    # retrying up to a given number of times
    # @param errors [Array<Exception>] the exceptions to trap
    # @param limit [Integer] the maximum number of retries
    # @param on_error [Proc] a block to call when an error occurs
    # @return the result of any successful completion of the block
    def retry_on_error(errors:, limit: 10, on_error: nil)
      tries ||= 1
      yield
    rescue *errors => e
      if tries < limit
        message = "#{e}, attempt #{tries} of #{limit}"
        Logger.logger.debug message
        on_error&.call
        tries += 1
        retry
      end
      raise e
    end
  end
end
