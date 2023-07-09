module Imap::Backup
  describe Setup::ConnectionTester do
    describe "#test" do
      subject { described_class.new(account) }

      let(:account) { instance_double(Account, client: client) }
      let(:client) { instance_double(Client::Default) }

      describe "success" do
        it "returns success" do
          expect(subject.test).to match(/successful/)
        end
      end

      describe "failure" do
        before do
          allow(account).to receive(:client).and_raise(error)
        end

        context "with no connection" do
          let(:error) do
            data = OpenStruct.new(text: "bar")
            response = OpenStruct.new(data: data)
            Net::IMAP::NoResponseError.new(response)
          end

          it "returns error" do
            expect(subject.test).to match(/no response/i)
          end
        end

        context "when caused by other errors" do
          let(:error) { "Error" }

          it "returns error" do
            expect(subject.test).to match(/unexpected error/i)
          end
        end
      end
    end
  end
end
