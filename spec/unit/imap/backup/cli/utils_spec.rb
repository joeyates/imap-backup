require "imap/backup/serializer/folder_maker"
require "support/shared_examples/an_action_that_handles_logger_options"

module Imap::Backup
  describe CLI::Utils do
    subject { described_class.new([], {quiet: true}) }

    let(:account) do
      instance_double(
        Account,
        username: email,
        local_path: "account_path",
        client: client
      )
    end
    let(:client) { instance_double(Client::Default, list: %w(foo)) }
    let(:serializer) do
      instance_double(
        Serializer,
        uids: %w(123 789),
        apply_uid_validity: nil,
        append: nil
      )
    end
    let(:email) { "foo@example.com" }
    let(:config) { instance_double(Configuration, accounts: [account]) }

    before do
      allow(Configuration).to receive(:exist?) { true }
      allow(Configuration).to receive(:new) { config }
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
      let(:serialized_folders) { instance_double(Account::SerializedFolders, none?: false) }
      let(:folder) do
        instance_double(
          Account::Folder,
          exist?: true,
          name: "name",
          uid_validity: "uid_validity",
          uids: %w(123 456)
        )
      end
      let(:exporter) { instance_double(Thunderbird::MailboxExporter, run: nil) }

      before do
        allow(Thunderbird::MailboxExporter).to receive(:new) { exporter }
        allow(Thunderbird::Profiles).to receive(:new) { profiles }
        allow(Account::SerializedFolders).to receive(:new) { serialized_folders }
        allow(subject).to receive(:options) { options }
        allow(serialized_folders).to receive(:each).and_yield("foo", "bar")
      end

      it_behaves_like(
        "an action that handles Logger options",
        action: ->(subject, options) do
          subject.invoke(:export_to_thunderbird, ["foo@example.com"], options)
        end
      )
      it_behaves_like(
        "an action that requires an existing configuration",
        action: ->(subject) do
          subject.invoke(:export_to_thunderbird, ["foo@example.com"])
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
      let(:backup_folders) { instance_double(Account::BackupFolders) }
      let(:folder) do
        instance_double(
          Account::Folder,
          exist?: true,
          name: "name",
          uid_validity: "uid_validity",
          uids: %w(123 456)
        )
      end

      before do
        allow(Account::BackupFolders).to receive(:new) { backup_folders }
        allow(backup_folders).to receive(:each).and_yield(folder)
      end

      it_behaves_like(
        "an action that requires an existing configuration",
        action: ->(subject) do
          subject.ignore_history("foo@example.com")
        end
      )

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
