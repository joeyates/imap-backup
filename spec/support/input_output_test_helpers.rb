module InputOutputTestHelpers
  def capturing_output
    output = StringIO.new
    $stdout = output
    yield
    output.string
  ensure
    $stdout = STDOUT
  end
end

