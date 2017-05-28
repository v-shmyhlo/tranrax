# frozen_string_literal: true

module Tranrax
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
end
