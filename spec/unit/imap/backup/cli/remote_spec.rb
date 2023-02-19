module Imap::Backup
  require "support/shared_examples/an_action_that_handle_logger_options"

  describe CLI::Remote do
    subject { described_class.new }

    let(:connection) do
      instance_double(Account::Connection, account: account, folder_names: %w[foo])
    end
    let(:account) { instance_double(Account, username: "user") }
    let(:config) { instance_double(Configuration, accounts: [account]) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Account::Connection).to receive(:new) { connection }
      allow(Kernel).to receive(:puts)
    end

    describe "#folders" do
      it "prints names of emails to be backed up" do
        subject.folders(account.username)

        expect(Kernel).to have_received(:puts).with('"foo"')
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: -> (subject, options) do
          subject.invoke(:folders, ["user"], options)
        end
      )
    end

    end
  end
end
