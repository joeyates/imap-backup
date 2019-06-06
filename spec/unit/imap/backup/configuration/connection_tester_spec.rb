describe Imap::Backup::Configuration::ConnectionTester do
  describe ".test" do
    let(:connection) do
      instance_double(Imap::Backup::Account::Connection, imap: nil)
    end
    let(:result) { subject.test("foo") }

    before do
      allow(Imap::Backup::Account::Connection).to receive(:new) { connection }
    end

    describe "call" do
      before { result }

      it "tries to connect" do
        expect(connection).to have_received(:imap)
      end
    end

    describe "success" do
      before { result }

      it "returns success" do
        expect(result).to match(/successful/)
      end
    end

    describe "failure" do
      before do
        allow(connection).to receive(:imap).and_raise(error)
        result
      end

      context "with no connection" do
        let(:error) do
          data = OpenStruct.new(text: "bar")
          response = OpenStruct.new(data: data)
          Net::IMAP::NoResponseError.new(response)
        end

        it "returns error" do
          expect(result).to match(/no response/i)
        end
      end

      context "when caused by other errors" do
        let(:error) { "Error" }

        it "returns error" do
          expect(result).to match(/unexpected error/i)
        end
      end
    end
  end
end
