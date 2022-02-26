module Imap::Backup
  describe CLI::Backup do
    subject { described_class.new({}) }

    let(:connection) { instance_double(Account::Connection, run_backup: nil) }

    before do
      allow(subject).to receive(:each_connection).with([]).and_yield(connection)
    end

    it "runs the backup for each connection" do
      subject.run

      expect(connection).to have_received(:run_backup)
    end
  end
end
