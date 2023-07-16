module Imap; end

module Imap::Backup
  class Serializer::Mbox
    attr_reader :folder_path

    def initialize(folder_path)
      @folder_path = folder_path
    end

    def valid?
      exist?
    end

    def append(message)
      File.open(pathname, "ab") do |file|
        file.write message
      end
    end

    def read(offset, length)
      File.open(pathname, "rb") do |f|
        f.seek offset
        f.read length
      end
    end

    def delete
      return if !exist?

      File.unlink(pathname)
    end

    def length
      return nil if !exist?

      File.stat(pathname).size
    end

    def pathname
      "#{folder_path}.mbox"
    end

    def rename(new_path)
      if exist?
        old_pathname = pathname
        @folder_path = new_path
        File.rename(old_pathname, pathname)
      else
        @folder_path = new_path
      end
    end

    def rewind(length)
      File.open(pathname, File::RDWR | File::CREAT, 0o644) do |f|
        f.truncate(length)
      end
    end

    def touch
      File.open(pathname, "a") {}
    end

    def exist?
      File.exist?(pathname)
    end
  end
end
