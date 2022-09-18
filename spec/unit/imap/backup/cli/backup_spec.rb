module Imap::Backup
  describe CLI::Backup do
    subject { described_class.new({}) }

    let(:account) { instance_double(Account) }
    let(:config) { instance_double(Configuration, accounts: [account]) }
    let(:connection) { instance_double(Account::Connection, run_backup: nil) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:each_connection).with(anything, []).and_yield(connection)
      # rubocop:enable RSpec/SubjectStub
    end

    it "runs the backup for each connection" do
      subject.run

      expect(connection).to have_received(:run_backup)
    end
  end
end
