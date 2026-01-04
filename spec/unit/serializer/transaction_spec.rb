require "imap/backup/serializer/transaction"

module Imap::Backup
  class FakeOwnerForTransaction; end

  RSpec.describe Serializer::Transaction do
    subject(:transaction) { described_class.new(owner: owner) }

    let(:owner) { FakeOwnerForTransaction.new }

    describe "#fail_in_transaction!" do
      it "does not raise outside a transaction" do
        expect { transaction.fail_in_transaction!(:run) }.to_not raise_error
      end

      it "raises inside a transaction" do
        expect do
          transaction.begin(:data) do
            transaction.fail_in_transaction!(:run)
          end
        end.to raise_error(RuntimeError, /FakeOwnerForTransaction#run not supported/)
      end
    end

    describe "#fail_outside_transaction!" do
      it "raises outside a transaction" do
        expect do
          transaction.fail_outside_transaction!(:run)
        end.to raise_error(RuntimeError, /FakeOwnerForTransaction#run can only be called/)
      end

      it "does not raise inside a transaction" do
        expect do
          transaction.begin(:data) do
            transaction.fail_outside_transaction!(:run)
          end
        end.to_not raise_error
      end
    end
  end
end
