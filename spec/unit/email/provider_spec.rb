describe Email::Provider do
  describe ".for_address" do
    context "with known providers" do
      [
        ["fastmail.com", "Fastmail .com", Email::Provider::Fastmail],
        ["fastmail.fm", "Fastmail .fm", Email::Provider::Fastmail],
        ["gmail.com", "GMail", Email::Provider::GMail],
        ["icloud.com", "Apple Mail icloud.com", Email::Provider::AppleMail],
        ["mac.com", "Apple Mail mac.com", Email::Provider::AppleMail],
        ["me.com", "Apple Mail me.com", Email::Provider::AppleMail],
        ["purelymail.com", "Purelymail me.com", Email::Provider::Purelymail]
      ].each do |domain, name, klass|
        it "recognizes #{name} addresses" do
          address = "foo@#{domain}"
          expect(described_class.for_address(address)).to be_a(klass)
        end
      end
    end

    context "with unknown providers" do
      it "returns the Unknown provider" do
        result = described_class.for_address("foo@unknown.com")

        expect(result).to be_a(Email::Provider::Unknown)
      end
    end
  end
end
