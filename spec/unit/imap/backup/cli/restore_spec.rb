# rubocop:disable RSpec/SubjectStub
module Imap::Backup
  describe CLI::Restore do
    subject { described_class.new(email, options) }

    let(:connection) { instance_double(Account::Connection, restore: nil) }
    let(:account) { instance_double(Account, username: email) }
    let(:config) { instance_double(Configuration, accounts: [account]) }
    let(:email) { "email" }
    let(:options) { {} }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
    end

    it_behaves_like(
      "an action that requires an existing configuration",
      action: ->(subject) { subject.run }
    )

    describe "#run" do
      context "when an email is provided" do
        before do
          allow(subject).to receive(:connection).with(anything, email) { connection }

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
          allow(subject).to receive(:each_connection).with(anything, []).and_yield(connection)

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
          allow(subject).to receive(:each_connection).
            with(anything, ["email2"]).and_yield(connection)

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
