describe Email::Provider::Base do
  describe "#options" do
    it "returns options" do
      expect(subject.options).to be_a(Hash)
    end

    it "forces TLSv1_2" do
      expect(subject.options[:ssl][:ssl_version]).to eq(:TLSv1_2)
    end
  end
end
