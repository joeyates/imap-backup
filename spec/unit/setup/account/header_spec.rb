require "imap/backup/setup/account/header"
require "highline"
require "imap/backup/account"

module Imap::Backup
  RSpec.describe Setup::Account::Header do
    subject { described_class.new(menu: menu, account: account) }

    let(:menu) { HighLine::Menu.new }
    let(:account) do
      instance_double(
        Account,
        username: "user@example.com",
        password: existing_password,
        local_path: "/backup/path",
        folders: ["my_folder"],
        mirror_mode: mirror_mode,
        server: "imap.example.com",
        connection_options: connection_options,
        modified?: modified,
        folder_blacklist: false,
        multi_fetch_size: multi_fetch_size,
        reset_seen_flags_after_fetch: reset_seen_flags_after_fetch
      )
    end
    let(:existing_password) { "password" }
    let(:mirror_mode) { nil }
    let(:connection_options) { nil }
    let(:modified) { false }
    let(:multi_fetch_size) { 2 }
    let(:reset_seen_flags_after_fetch) { false }

    [
      ["email", /email\s+user@example.com/],
      ["password", /password\s+x+/],
      ["path", %r(path\s+/backup/path)],
      ["folders to be backed up", /include\s+my_folder/],
      ["mode", /keep/],
      ["server", /server\s+imap.example.com/]
    ].each do |attribute, value|
      before { subject.run }

      it "shows the #{attribute}" do
        expect(menu.header).to match(value)
      end
    end

    it "does not indicate modification" do
      expect(menu.header).to match(/Account$/)
    end

    context "when the account is modified" do
      let(:modified) { true }

      it "indicates modification" do
        expect(menu.header).to match(/Account\*$/)
      end
    end

    context "with no password" do
      let(:existing_password) { "" }

      before { subject.run }

      it "indicates that a password is not set" do
        expect(menu.header).to match(/^password\s+\(unset\)/)
      end
    end

    context "with mirror_mode" do
      let(:mirror_mode) { true }

      it "indicates the flag is set" do
        expect(menu.header).to match(/mirror/)
      end
    end

    context "with multi_fetch_size" do
      let(:multi_fetch_size) { 4 }

      it "shows the size" do
        expect(menu.header).to match(/^multi-fetch\s+4/)
      end
    end

    context "with connection_options" do
      let(:connection_options) { {some: "option"} }

      it "shows the options" do
        expect(menu.header).to match(/^connection options\s+'{\\"some\\":\\"option\\"}'/)
      end
    end

    context "with reset_seen_flags_after_fetch" do
      let(:reset_seen_flags_after_fetch) { true }

      it "indicates the flag is set" do
        expect(menu.header).to match(/^changes to unread flags will be reset/)
      end
    end
  end
end
