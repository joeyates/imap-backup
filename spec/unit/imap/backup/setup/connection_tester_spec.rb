module Imap::Backup
  RSpec.describe Setup::ConnectionTester do
    describe "#test" do
      subject { described_class.new(account) }

      let(:account) { instance_double(Account, client: client) }
      let(:client) { instance_double(Client::Default, login: nil) }

      describe "success" do
        it "attempts to login" do
          subject.test

          expect(client).to have_received(:login)
        end

        it "returns success" do
          expect(subject.test).to match(/successful/)
        end
      end

      describe "failure" do
        before do
          allow(client).to receive(:login).and_raise(error)
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
