require 'tranrax/version'

module Tranrax
  # TODO: return transaction monad type instead of ducktyping
  # kinda like: operation :: a -> b -> Transaction a
  # TODO: probably call should return tuple of type (Result, RollbackData) and use RollbackData for rollback and result for result

  module TransactionMonad
    # transact :: Transaction a -> (a -> b) -> b
    def transact
      (result, rollback, postcommit) = @computation.call

      begin
        transaction_result = yield result
      rescue => e
        rollback.call unless rollback.nil?
        raise e
      end

      postcommit.call unless postcommit.nil?

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

  class Mapped
    include TransactionMonad

    def initialize(parent, &block)
      @parent = parent
      @block = block
    end

    def transact
      @parent.transact do |value|
        yield @block.call(value)
      end
    end
  end

  class Binded
    include TransactionMonad

    def initialize(parent, &block)
      @parent = parent
      @block = block
    end

    def transact
      @parent.transact do |x|
        @block.call(x).transact do |y|
          yield y
        end
      end
    end
  end

  class Transaction
    include TransactionMonad

    def initialize(&computation)
      @computation = computation
    end
  end
end
