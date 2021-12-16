describe Email::Provider::Default do
  describe "#host" do
    it "is unset" do
      expect(subject.host).to be_nil
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
end
