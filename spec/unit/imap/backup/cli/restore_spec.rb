# rubocop:disable RSpec/SubjectStub
module Imap::Backup
  describe CLI::Restore do
    subject { described_class.new(email, options) }

    let(:connection) { instance_double(Account::Connection, restore: nil) }

    describe "#run" do
      context "when an email is provided" do
        let(:email) { "email" }
        let(:options) { {} }

        before do
          allow(subject).to receive(:connection).with(email) { connection }

          subject.run
        end

        it "runs restore on the account" do
          expect(connection).to have_received(:restore)
        end
      end

      context "when neither an email nor a list of account names is provided" do
        let(:email) { nil }
        let(:options) { {} }

        before do
          allow(subject).to receive(:each_connection).with([]).and_yield(connection)

          subject.run
        end

        it "runs restore on each account" do
          expect(connection).to have_received(:restore)
        end
      end

      context "when an email and a list of account names is provided" do
        let(:email) { "email" }
        let(:options) { {accounts: "email2"} }

        it "fails" do
          expect do
            subject.run
          end.to raise_error(RuntimeError, /Pass either an email or the --accounts option/)
        end
      end

      context "when just a list of account names is provided" do
        let(:email) { nil }
        let(:options) { {accounts: "email2"} }

        before do
          allow(subject).to receive(:each_connection).with(["email2"]).and_yield(connection)

          subject.run
        end

        it "runs restore on each account" do
          expect(connection).to have_received(:restore)
        end
      end
    end
  end
end
# rubocop:enable RSpec/SubjectStub
