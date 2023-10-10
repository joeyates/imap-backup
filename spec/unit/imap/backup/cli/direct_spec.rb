require "imap/backup/cli/direct"

module Imap::Backup
  RSpec.describe CLI::Direct do
    subject { described_class.new(options) }

    describe "#handle_password_options!" do
      let(:options) { {} }

      context "when --password is supplied" do
        let(:options) { {password: "plain"} }

        it "accepts the option" do
          subject.handle_password_options!

          expect(subject.password).to eq ("plain")
        end
      end

      context "when --password-environment-variable is supplied" do
        let(:options) { {password_environment_variable: "env"} }

        before do
          allow(ENV).to receive(:fetch).and_call_original
          allow(ENV).to receive(:fetch).with("env") { "value" }
        end

        it "accepts the option" do
          subject.handle_password_options!

          expect(subject.password).to eq ("value")
        end
      end

      context "when --password-file is supplied" do
        let(:options) { {password_file: "some/path"} }
        let(:file_content) { "text" }

        before do
          allow(File).to receive(:read).and_call_original
          allow(File).to receive(:read).with("some/path") { file_content }
        end

        it "accepts the option" do
          subject.handle_password_options!

          expect(subject.password).to eq ("text")
        end

        context "when the file ends with a newline character" do
          let(:file_content) { "text\n" }

          it "is trimmed" do
            subject.handle_password_options!

            expect(subject.password).to eq ("text")
          end
        end
      end

      context "when no --password... option is set" do
        it "fails" do
          expect do
            subject.handle_password_options!
          end.to raise_error(Thor::RequiredArgumentMissingError, /--password/)
        end
      end

      [
        %w(password password-environment-variable),
        %w(password password-file),
        %w(password-environment-variable password-file)
      ].each do |parameter_1, parameter_2|
        context "when both --#{parameter_1} and --#{parameter_2} are set" do
          let(:options) do
            {
              parameter_1.tr("-", "_").to_sym => "v1",
              parameter_2.tr("-", "_").to_sym => "v2"
            }
          end

          it "fails" do
            expect do
              subject.handle_password_options!
            end.to raise_error(ArgumentError, /Supply only one/)
          end
        end
      end
    end
  end
end
