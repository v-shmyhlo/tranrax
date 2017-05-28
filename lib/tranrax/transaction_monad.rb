# frozen_string_literal: true

module Tranrax
  module TransactionMonad
    # transact :: Transaction a -> (a -> b) -> b
    def transact
      (result, rollback, postcommit) = @computation.call

      begin
        transaction_result = yield result
      rescue => e
        rollback&.call
        raise e
      end

      postcommit&.call

      transaction_result
    end

    # map :: Transaction a -> (a -> b) -> Transaction b
    def map(&block)
      Mapped.new(self, &block)
    end

    # bind :: Transaction a -> (a -> Transaction b) -> Transaction b
    def bind(&block)
      Binded.new(self, &block)
    end
  end
end
