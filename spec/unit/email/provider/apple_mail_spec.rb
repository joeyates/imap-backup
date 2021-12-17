describe Email::Provider::AppleMail do
  describe "#host" do
    it "returns host" do
      expect(subject.host).to eq("imap.mail.me.com")
    end
  end
end
