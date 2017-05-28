# frozen_string_literal: true

module Tranrax
  class Result
    def self.result(value = nil)
      new(value: value, rollbacks: [], postcommits: [])
    end

    def initialize(value:, rollbacks:, postcommits:)
      @value = value
      @rollbacks = rollbacks
      @postcommits = postcommits
    end

    def rollback(&block)
      Result.new(value: @value, rollbacks: [*@rollbacks, block], postcommits: @postcommits)
    end

    def postcommit(&block)
      Result.new(value: @value, rollbacks: @rollbacks, postcommits: [*@postcommits, block])
    end

    def to_a
      [@value, -> { @rollbacks.each(&:call) }, -> { @postcommits.each(&:call) }]
    end
  end
end
