class Retrier
  class FooError < StandardError; end

  include RetryOnError

  def do_stuff(errors:, limit: 10, on_error: nil)
    calls = 0

    retry_on_error(errors: errors, limit: limit, on_error: on_error) do
      calls += 1
      raise FooError, "Failed!" if calls < 3

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
        end.to raise_error(Retrier::FooError, /Failed/)
      end
    end

    context "when unexpected errors are raised" do
      it "fails" do
        expect do
          subject.do_stuff(errors: [RuntimeError])
        end.to raise_error(Retrier::FooError, /Failed/)
      end
    end

    context "when an :on_error block is passed" do
      it "calls the block before retrying" do
        on_error_calls = 0
        error_proc = -> { on_error_calls += 1 }
        subject.do_stuff(errors: [Retrier::FooError], on_error: error_proc)

        expect(on_error_calls).to eq(2)
      end
    end
  end
end
