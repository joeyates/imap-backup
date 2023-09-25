module RetryOnError
  def retry_on_error(errors:, limit: 10, on_error: nil)
    tries ||= 1
    yield
  rescue *errors => e
    if tries < limit
      message = "#{e}, attempt #{tries} of #{limit}"
      Imap::Backup::Logger.logger.debug message
      on_error&.call
      tries += 1
      retry
    end
    raise e
  end
end
