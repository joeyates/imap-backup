describe Email::Provider do
  subject { described_class.new(:gmail) }

  describe ".for_address" do
    context "with known providers" do
      [
        ["gmail.com", :gmail],
        ["fastmail.fm", :fastmail]
      ].each do |domain, provider|
        it "recognizes #{provider}" do
          address = "foo@#{domain}"
          expect(described_class.for_address(address).provider).to eq(provider)
        end
      end
    end

    context "with unknown providers" do
      it "returns a default provider" do
        result = described_class.for_address("foo@unknown.com").provider
        expect(result).to eq(:default)
      end
    end
  end

  describe "#options" do
    it "returns options" do
      expect(subject.options).to be_a(Hash)
    end

    it "forces TLSv1_2" do
      expect(subject.options[:ssl][:ssl_version]).to eq(:TLSv1_2)
    end
  end

  describe "#host" do
    it "returns host" do
      expect(subject.host).to eq("imap.gmail.com")
    end
  end
end
