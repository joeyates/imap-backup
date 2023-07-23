module Imap::Backup
  RSpec.describe CLI::Backup do
    subject { described_class.new({}) }

    let(:account) { instance_double(Account, username: "me@example.com") }
    let(:backup) { instance_double(Account::Backup, "backup", run: nil) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Account::Backup).to receive(:new) { backup }
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:requested_accounts) { [account] }
      # rubocop:enable RSpec/SubjectStub
    end

    it_behaves_like(
      "an action that requires an existing configuration",
      action: ->(subject) { subject.run }
    )

    it "runs the backup for each connection" do
      subject.run

      expect(backup).to have_received(:run)
    end

    context "when one connection fails" do
      let(:account2) { instance_double(Account, "account2") }

      before do
        outcomes = [-> { raise "Foo" }, -> { true }]
        allow(backup).to receive(:run) { outcomes.shift.call }

        # rubocop:disable RSpec/SubjectStub
        allow(subject).to receive(:requested_accounts) { [account, account2] }
        # rubocop:enable RSpec/SubjectStub
      end

      it "runs other backups" do
        subject.run

        expect(backup).to have_received(:run).twice
      end
    end
  end
end
