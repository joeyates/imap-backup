require "imap/backup/cli/single/backup"

module Imap::Backup
  RSpec.describe CLI::Single::Backup do
    subject { described_class.new(options) }

    let(:account) do
      instance_double(
        Account,
        "connection_options=": nil,
        "folder_blacklist=": nil,
        "folders=": nil,
        "multi_fetch_size=": nil
      )
    end
    let(:backup) { instance_double(Account::Backup, run: nil) }
    let(:good_options) { {email: "me", password: "plain", server: "host"} }

    before do
      allow(Account).to receive(:new) { account }
      allow(Account::Backup).to receive(:new) { backup }
    end

    context "when the correct parameters are supplied" do
      let(:options) { good_options }

      it "runs the backup" do
        subject.run

        expect(backup).to have_received(:run)
      end

      it "uses the email value" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(username: "me"))
      end

      it "uses the server value" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(server: "host"))
      end
    end

    context "when no --email option is set" do
      let(:options) { {server: "host", password: "plain"} }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(Thor::RequiredArgumentMissingError, /--email/)
      end
    end

    context "when --password is supplied" do
      let(:options) { {email: "me", password: "plain", server: "host"} }

      it "is used" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(password: "plain"))
      end
    end

    context "when --password-environment-variable is supplied" do
      let(:options) do
        {email: "me", server: "host", password_environment_variable: "env"}
      end

      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with("env") { "value" }
      end

      it "is used" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(password: "value"))
      end
    end

    context "when --password-file is supplied" do
      let(:options) { {email: "me", password_file: "some/path", server: "host"} }
      let(:file_content) { "text" }

      before do
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with("some/path") { file_content }
      end

      it "is used" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(password: "text"))
      end

      context "when the file ends with a newline character" do
        let(:file_content) { "some text\n" }

        it "is trimmed" do
          subject.run

          expect(Account).to have_received(:new).
            with(hash_including(password: "some text"))
        end
      end
    end

    context "when no --password... option is set" do
      let(:options) { {email: "me", server: "host"} }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(Thor::RequiredArgumentMissingError, /--password/)
      end
    end

    [
      %w(password password-environment-variable),
      %w(password password-file),
      %w(password-environment-variable password-file)
    ].each do |parameter1, parameter2|
      context "when both --#{parameter1} and --#{parameter2} are set" do
        let(:options) do
          {
            email: "me",
            server: "host",
            parameter1.tr("-", "_").to_sym => "v1",
            parameter2.tr("-", "_").to_sym => "v2"
          }
        end

        it "fails" do
          expect do
            subject.run
          end.to raise_error(ArgumentError, /Supply only one/)
        end
      end
    end

    context "when a --path is supplied" do
      let(:options) { good_options.merge(path: "my/path") }

      it "uses that path" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(local_path: "my/path"))
      end
    end

    context "when no --path is supplied" do
      let(:options) { good_options }

      it "backs up to a local directory" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(local_path: File.join(Dir.pwd, "me")))
      end
    end

    context "when a --folder Array is supplied" do
      let(:options) { good_options.merge(folder: ["INBOX"]) }

      it "uses the values" do
        subject.run

        expect(account).to have_received(:folders=).with(["INBOX"])
      end
    end

    context "when no --folder parameter is supplied" do
      let(:options) { good_options }

      it "does not set a folders list" do
        subject.run

        expect(account).to_not have_received(:folders=)
      end
    end

    context "when a --folder-blacklist parameter is supplied" do
      let(:options) { good_options.merge(folder_blacklist: true) }

      it "sets the flag" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(folder_blacklist: true))
      end
    end

    context "when no --folder-blacklist parameter is supplied" do
      let(:options) { good_options }

      it "unsets the flag" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(folder_blacklist: false))
      end
    end

    context "when a --mirror parameter is supplied" do
      let(:options) { good_options.merge(mirror: true) }

      it "sets the flag" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(mirror_mode: true))
      end
    end

    context "when no --mirror parameter is supplied" do
      let(:options) { good_options }

      it "unsets the flag" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(mirror_mode: false))
      end
    end

    context "when --multi-fetch-size is supplied" do
      let(:options) { good_options.merge(multi_fetch_size: 42) }

      it "is used" do
        subject.run

        expect(account).to have_received(:multi_fetch_size=).with(42)
      end
    end

    context "when no --multi-fetch-size is supplied" do
      let(:options) { good_options }

      it "is not set" do
        subject.run

        expect(account).to_not have_received(:multi_fetch_size=)
      end
    end

    context "when --connection-options is supplied" do
      let(:options) { good_options.merge(connection_options: "{}") }

      it "is used" do
        subject.run

        expect(account).to have_received(:connection_options=).with("{}")
      end
    end

    context "when no --connection-options is supplied" do
      let(:options) { good_options }

      it "is not set" do
        subject.run

        expect(account).to_not have_received(:connection_options=)
      end
    end

    context "when a --download-strategy is supplied" do
      let(:options) { good_options.merge(download_strategy: "direct") }

      it "is used" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(download_strategy: "direct"))
      end
    end

    context "when no --download-strategy is supplied" do
      let(:options) { good_options }

      it "is used" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(download_strategy: "delay_metadata"))
      end
    end

    context "when an unknown --download-strategy is supplied" do
      let(:options) { good_options.merge(download_strategy: "foo") }

      it "fails" do
        expect do
          subject.run
        end.to raise_error(ArgumentError, /Unknown download_strategy/)
      end
    end

    context "when a --refresh parameter is supplied" do
      let(:options) { good_options.merge(refresh: true) }

      it "sets the flag" do
        subject.run

        expect(Account::Backup).to have_received(:new).
          with(hash_including(refresh: true))
      end
    end

    context "when no --refresh parameter is supplied" do
      let(:options) { good_options }

      it "unsets the flag" do
        subject.run

        expect(Account::Backup).to have_received(:new).
          with(hash_including(refresh: false))
      end
    end

    context "when a --reset-seen-flags-after-fetch parameter is supplied" do
      let(:options) { good_options.merge(reset_seen_flags_after_fetch: true) }

      it "sets the flag" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(reset_seen_flags_after_fetch: true))
      end
    end

    context "when no --reset-seen-flags-after-fetch parameter is supplied" do
      let(:options) { good_options }

      it "unsets the flag" do
        subject.run

        expect(Account).to have_received(:new).
          with(hash_including(reset_seen_flags_after_fetch: false))
      end
    end
  end
end
