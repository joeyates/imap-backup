require "spec_helper"

describe Imap::Backup::Configuration::ConnectionTester do
  context ".test" do
    let(:connection) { double("Imap::Backup::Account::Connection", imap: nil) }

    before do
      allow(Imap::Backup::Account::Connection).to receive(:new) { connection }
    end

    context "call" do
      before { @result = subject.test("foo") }

      it "tries to connect" do
        expect(connection).to have_received(:imap)
      end
    end

    context "success" do
      before { @result = subject.test("foo") }

      it "returns success" do
        expect(@result).to match(/successful/)
      end
    end

    context "failure" do
      before do
        allow(connection).to receive(:imap).and_raise(error)
        @result = subject.test("foo")
      end

      context "no connection" do
        let(:error) do
          data = double("foo", text: "bar")
          Net::IMAP::NoResponseError.new(double("o", data: data))
        end

        it "returns success" do
          expect(@result).to match(/no response/i)
        end
      end

      context "other" do
        let(:error) { "Error" }
        it "returns success" do
          expect(@result).to match(/unexpected error/i)
        end
      end
    end
  end
end
