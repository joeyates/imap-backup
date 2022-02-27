class Retrier
  class FooError < StandardError; end

  include RetryOnError

  def do_stuff(errors:, limit:)
    calls = 0

    retry_on_error(errors: errors, limit: limit) do
      calls += 1
      raise FooError if calls < 3

      42
    end
  end
end

RSpec.describe RetryOnError do
  describe "#retry_on_error" do
    subject { Retrier.new }

    it "retries" do
      expect(subject.do_stuff(errors: [Retrier::FooError], limit: 3)).to eq(42)
    end

    context "when the block fails more than the limit" do
      it "fails" do
        expect do
          subject.do_stuff(errors: [Retrier::FooError], limit: 1)
        end.to raise_error(Retrier::FooError)
      end
    end
  end
end
