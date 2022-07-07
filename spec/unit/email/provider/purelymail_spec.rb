describe Email::Provider::Purelymail do
  describe "#sets_seen_flags_on_fetch?" do
    it "is true" do
      expect(subject.sets_seen_flags_on_fetch?).to be true
    end
  end
end
