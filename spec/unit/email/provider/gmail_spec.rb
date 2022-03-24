# rubocop:disable RSpec/FilePath
describe Email::Provider::GMail do
  describe "#host" do
    it "returns host" do
      expect(subject.host).to eq("imap.gmail.com")
    end
  end
end
# rubocop:enable RSpec/FilePath
