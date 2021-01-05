module Google
  module Auth
    module Stores
      class InMemoryTokenStore < Hash
        def load(id)
          self[id]
        end
      end
    end
  end
end
