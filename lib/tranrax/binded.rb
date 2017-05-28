# frozen_string_literal: true

module Tranrax
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
end
