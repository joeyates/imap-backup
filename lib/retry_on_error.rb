module RetryOnError
  def retry_on_error(errors:, limit: 10)
    tries ||= 1
    yield
  rescue *errors => e
    if tries < limit
      message = "#{e}, attempt #{tries} of #{limit}"
      Imap::Backup.logger.debug message
      tries += 1
      retry
    end
    raise e
  end
end
