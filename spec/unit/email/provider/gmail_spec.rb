RSpec.describe Email::Provider::GMail do
  describe "#host" do
    it "returns host" do
      expect(subject.host).to eq("imap.gmail.com")
    end
  end
end
