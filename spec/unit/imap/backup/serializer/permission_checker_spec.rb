require "imap/backup/serializer/permission_checker"

module Imap::Backup
  describe Serializer::PermissionChecker do
    subject { described_class.new(filename: "filename", limit: 0o345) }

    let(:file_mode) { instance_double(FileMode, mode: mode) }
    let(:mode) {}

    before do
      allow(FileMode).to receive(:new) { file_mode }
    end

    [
      [0o100, "less than the limit", true],
      [0o345, "equal to the limit", true],
      [0o777, "over the limit", false]
    ].each do |mode, description, success|
      context "when permissions are #{description}" do
        let(:mode) { mode }

        if success
          it "succeeds" do
            subject.run
          end
        else
          it "fails" do
            message = /Permissions on '.*?' should be .*?, not .*?/
            expect do
              subject.run
            end.to raise_error(RuntimeError, message)
          end
        end
      end
    end

    context "with non-existent files" do
      it "succeeds" do
        subject.run
      end
    end
  end
end
