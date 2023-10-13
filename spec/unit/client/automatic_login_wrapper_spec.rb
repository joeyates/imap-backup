require "imap/backup/client/automatic_login_wrapper"

require "imap/backup/client/default"

module Imap::Backup
  RSpec.describe Client::AutomaticLoginWrapper do
    subject { described_class.new(client: client) }

    let(:client) { instance_double(Client::Default, examine: nil, login: nil) }

    context "when #login is called" do
      it "logs in" do
        subject.login

        expect(client).to have_received(:login).once
      end
    end

    context "when any other method is called" do
      it "logs in first" do
        subject.examine("foo")

        expect(client).to have_received(:login)
      end
    end

    context "when further methods are called" do
      it "logs in first" do
        subject.examine("foo")
        subject.examine("bar")

        expect(client).to have_received(:login).once
      end
    end

    context "when #login is called explicitly more than once" do
      it "calls #login" do
        subject.login
        subject.login

        expect(client).to have_received(:login).twice
      end
    end

    context "when the first login attempt fails" do
      before do
        outcomes = [-> { raise EOFError }, -> { true }]
        allow(client).to receive(:login) { outcomes.shift.call }
      end

      it "retries" do
        subject.examine("bar")

        expect(client).to have_received(:login).twice
      end
    end
  end
end
