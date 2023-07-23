RSpec.describe Text::Sanitizer do
  require "stringio"

  subject { described_class.new(output) }

  let(:output) { StringIO.new }

  describe "#puts" do
    it "delegates to output" do
      subject.puts("x")

      expect(output.string).to eq("x\n")
    end
  end

  describe "#write" do
    it "delegates to output" do
      subject.write("x")

      expect(output.string).to eq("x")
    end
  end

  describe "#print" do
    it "removes passwords from complete lines of text" do
      subject.print("C: RUBY99 LOGIN xx) secret!!!!\netc")

      expect(output.string).to eq("C: RUBY99 LOGIN xx) [PASSWORD REDACTED]\n")
    end
  end

  describe "#flush" do
    it "sanitizes remaining text" do
      subject.print("before\nC: RUBY99 LOGIN xx) secret!!!!")
      subject.flush

      expect(output.string).to eq("before\nC: RUBY99 LOGIN xx) [PASSWORD REDACTED]\n")
    end
  end
end
