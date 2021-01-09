module Google; end
module Google::Auth; end
module Google::Auth::Stores; end

class Google::Auth::Stores::InMemoryTokenStore < Hash
  def load(id)
    self[id]
  end
end
