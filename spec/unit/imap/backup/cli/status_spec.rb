module Imap::Backup
  describe CLI::Status do
    subject { described_class.new({}) }

    let(:connection) { instance_double(Account::Connection, account: account, status: status) }
    let(:account) { instance_double(Account, username: "user") }
    let(:status) { [{remote: [1, 2, 3], local: [1, 2], name: "foo"}] }

    before do
      allow(Kernel).to receive(:puts)
      # rubocop:disable RSpec/SubjectStub
      allow(subject).to receive(:each_connection).with(anything, []).and_yield(connection)
      # rubocop:enable RSpec/SubjectStub

      subject.run
    end

    it "prints counts of emails to be backed up" do
      expect(Kernel).to have_received(:puts).with("foo: 1")
    end
  end
end
