require "forwardable"
require "net/imap"

module Imap::Backup
  module Client; end

  class Client::Default
    extend Forwardable
    def_delegators :imap, *%i(
      append authenticate create disconnect examine
      login responses uid_fetch uid_search
    )

    attr_reader :args

    def initialize(*args)
      @args = args
    end

    def list
      root = provider_root
      mailbox_lists = imap.list(root, "*")

      return [] if mailbox_lists.nil?

      utf7_encoded = mailbox_lists.map(&:name)
      utf7_encoded.map { |n| Net::IMAP.decode_utf7(n) }
    end

    private

    def imap
      @imap ||= Net::IMAP.new(*args)
    end

    # 6.3.8. LIST Command
    # An empty ("" string) mailbox name argument is a special request to
    # return the hierarchy delimiter and the root name of the name given
    # in the reference.
    def provider_root
      @provider_root ||= begin
        root_info = imap.list("", "")[0]
        root_info.name
      end
    end
  end
end
