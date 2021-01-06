describe Imap::Backup::Configuration::GMailOAuth2 do
  include HighLineTestHelpers

  describe "#run" do
    subject { described_class.new(account) }

    let(:account) { {folders: []} }

    it "is implemented" do
      subject.run
    end

    it "requests client_id"
    it "requests client_secret"
    it "displays the authorization URL"
    it "requests the success code"
    it "requests an access_token via the code"
    it "the credentials"
    it "includes the client_secret in the credentials"
  end
end
