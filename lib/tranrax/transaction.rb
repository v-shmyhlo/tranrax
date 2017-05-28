# frozen_string_literal: true

module Tranrax
  # TODO: return transaction monad type instead of ducktyping
  # kinda like: operation :: a -> b -> Transaction a
  # TODO: probably call should return tuple of type (Result, RollbackData) and use RollbackData for rollback and result for result

  class Transaction
    include TransactionMonad

    def initialize(&computation)
      @computation = computation
    end
  end
end
