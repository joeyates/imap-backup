module Imap::Backup
  describe CLI::Backup do
    subject { described_class.new({}) }

    let(:connection) { instance_double(Account::Connection, run_backup: nil) }

    before do
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:each_connection).with([]).and_yield(connection)
      # rubocop:enable RSpec/SubjectStub
    end

    it "runs the backup for each connection" do
      subject.run

      expect(connection).to have_received(:run_backup)
    end
  end
end
