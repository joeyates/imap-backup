require "support/shared_examples/an_action_that_handle_logger_options"

module Imap::Backup
  describe CLI::Utils do
    let(:account) do
      instance_double(
        Account,
        username: email,
        local_path: "path"
      )
    end
    let(:connection) do
      instance_double(
        Account::Connection,
        account: account,
        backup_folders: [folder],
        local_folders: ["folder"]
      )
    end
    let(:folder) do
      instance_double(
        Account::Folder,
        exist?: true,
        name: "name",
        uid_validity: "uid_validity",
        uids: %w(123 456)
      )
    end
    let(:serializer) do
      instance_double(
        Serializer,
        uids: %w(123 789),
        apply_uid_validity: nil,
        append: nil
      )
    end
    let(:exporter) { instance_double(Thunderbird::MailboxExporter, run: nil) }
    let(:email) { "foo@example.com" }
    let(:config) { instance_double(Configuration, accounts: [account]) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
      allow(Account::Connection).to receive(:new) { connection }
      allow(Serializer).to receive(:new) { serializer }
    end

    describe "#export_to_thunderbird" do
      let(:command) { subject.export_to_thunderbird(email) }
      let(:options) { {} }
      let(:profiles) do
        instance_double(Thunderbird::Profiles, installs: installs, profile: named_profile)
      end
      let(:installs) { [install1] }
      let(:install1) { instance_double(Thunderbird::Install, default: default_install) }
      let(:default_install) { "default" }
      let(:named_profile) { "named" }

      before do
        allow(Thunderbird::MailboxExporter).to receive(:new) { exporter }
        allow(Thunderbird::Profiles).to receive(:new) { profiles }
        allow(subject).to receive(:options) { options }
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:export_to_thunderbird, ["foo@example.com"], options)
        end
      )

      context "when no profile_name is supplied" do
        context "when no default Thunderbird profile is found" do
          let(:default_install) { nil }

          it "fails" do
            expect do
              command
            end.to raise_error(RuntimeError, /Default .*? not found/)
          end
        end

        context "when there is more than one install" do
          let(:installs) { [install1, install2] }
          let(:install2) { instance_double(Thunderbird::Install, default: default_install) }

          it "fails" do
            expect do
              command
            end.to raise_error(RuntimeError, /multiple installs.*?supply a profile name/m)
          end
        end
      end

      context "when a profile_name is supplied" do
        let(:options) { {profile: "profile"} }

        context "when the supplied profile_name is not found" do
          let(:named_profile) { nil }

          it "fails" do
            expect do
              command
            end.to raise_error(RuntimeError, /profile 'profile' not found/)
          end
        end
      end

      it "exports the profile" do
        command

        expect(exporter).to have_received(:run)
      end
    end

    describe "#ignore_history" do
      it "ensures the local UID validity matches the server" do
        subject.ignore_history(email)

        expect(serializer).to have_received(:apply_uid_validity).with("uid_validity")
      end

      it "fills the local folder with fake emails" do
        subject.ignore_history(email)

        expect(serializer).to have_received(:append).with("456", /From: fake@email.com/, [])
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:ignore_history, ["foo@example.com"], options)
        end
      )
    end
  end
end
