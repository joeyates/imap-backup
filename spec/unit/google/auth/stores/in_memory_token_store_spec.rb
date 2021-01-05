require "google/auth/stores/in_memory_token_store"

describe Google::Auth::Stores::InMemoryTokenStore do
  KEY = "key"
  VALUE = "value"

  subject { described_class.new() }

  describe "#load" do
    it "returns an item's value" do
      subject[KEY] = VALUE
      expect(subject.load(KEY)).to eq(VALUE)
    end
  end
end
