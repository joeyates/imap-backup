module Imap::Backup
  describe CLI::Backup do
    subject { described_class.new({}) }

    let(:account) { instance_double(Account, username: "me@example.com") }
    let(:config) { instance_double(Configuration, accounts: []) }
    let(:connection) { instance_double(Account::Connection, account: account, run_backup: nil) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:each_connection).with(anything, []).and_yield(connection)
      # rubocop:enable RSpec/SubjectStub
    end

    it "runs the backup for each connection" do
      subject.run

      expect(connection).to have_received(:run_backup)
    end

    context "when one connection fails" do
      let(:account2) { instance_double(Account) }
      let(:connection2) { instance_double(Account::Connection, run_backup: nil) }

      before do
        allow(connection).to receive(:run_backup).and_raise("Foo")

        # rubocop:disable RSpec/SubjectStub
        allow(subject).
          to receive(:each_connection).with(anything, []).
          and_yield(connection).
          and_yield(connection2)
        # rubocop:enable RSpec/SubjectStub
      end

      it "runs other backups" do
        subject.run

        expect(connection2).to have_received(:run_backup)
      end
    end
  end
end
