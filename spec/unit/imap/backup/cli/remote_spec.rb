require "ostruct"
require "support/shared_examples/an_action_that_handles_logger_options"

module Imap::Backup
  RSpec.describe CLI::Remote do
    let(:account) do
      instance_double(Account, client: client, namespaces: namespaces, username: "user")
    end
    let(:client) { instance_double(Client::Default, list: %w(foo)) }
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
      allow(Kernel).to receive(:puts)
    end

    describe "#folders" do
      it_behaves_like(
        "an action that requires an existing configuration",
        action: ->(subject) { subject.folders("email") }
      )

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
      it_behaves_like(
        "an action that requires an existing configuration",
        action: ->(subject) { subject.namespaces("email") }
      )

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
