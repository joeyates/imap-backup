require "ostruct"
require "support/shared_examples/an_action_that_handles_logger_options"

module Imap::Backup
  describe CLI::Remote do
    let(:connection) do
      instance_double(
        Account::Connection,
        account: account,
        folder_names: %w[foo],
        namespaces: namespaces
      )
    end
    let(:account) { instance_double(Account, username: "user") }
    let(:config) { instance_double(Configuration, accounts: [account]) }
    let(:namespaces) do
      OpenStruct.new(
        personal: [OpenStruct.new(prefix: "x", delim: "/")],
        other: [OpenStruct.new(prefix: "x", delim: "/")],
        shared: [OpenStruct.new(prefix: "x", delim: "/")]
      )
    end

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
        action: ->(subject, options) do
          subject.invoke(:folders, ["user"], options)
        end
      )
    end

    describe "#namespaces" do
      it "prints namespaces with prefixes and delimiters" do
        subject.invoke(:namespaces, [account.username], format: "json")

        expect(Kernel).to have_received(:puts).with(%r({"personal":{"prefix":"x","delim":"/"}))
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:namespaces, ["user"], options)
        end
      )
    end
  end
end
