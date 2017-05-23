require 'spec_helper'
require 'securerandom'
require 'fileutils'

describe Tranrax do
  it 'has a version number' do
    expect(Tranrax::VERSION).not_to be nil
  end

  describe Tranrax::Transaction do
    shared_examples :transaction do
      context 'when transaction succeeds' do
        def transact
          subject.transact { |value| yield value }
        end

        it 'has correct result' do
          transact { |value| expect(value).to eq(result) }
        end

        it 'returns correct transaction result' do
          actual = transact { :ok }

          expect(actual).to eq(:ok)
        end

        it 'runs postcommit after transaction' do
          transact { postcommits.each { |x| expect(x).not_to have_received(:call) } }

          postcommits.each { |x| expect(x).to have_received(:call) }
        end

        it 'doesnt run rollback' do
          transact {}

          rollbacks.each { |x| expect(x).not_to have_received(:call) }
        end
      end

      context 'when transaction fails' do
        def transact
          subject.transact { raise StandardError, 'Some Error' }
        rescue
          nil
        end

        it 'raises error' do
          expect do
            subject.transact { raise StandardError, 'Some Error' }
          end.to raise_error(StandardError, 'Some Error')
        end

        it 'doesnt run postcommit' do
          transact

          postcommits.each { |x| expect(x).not_to have_received(:call) }
        end

        it 'runs rollback' do
          transact

          rollbacks.each { |x| expect(x).to have_received(:call) }
        end
      end
    end

    def add_rollback
      rollback = spy(:rollback)
      rollbacks << rollback
      rollback
    end

    def add_postcommit
      postcommit = spy(:postcommit)
      postcommits << postcommit
      postcommit
    end

    let(:rollbacks) { [] }
    let(:postcommits) { [] }

    describe 'basic' do
      subject do
        described_class.new do
          [99, add_rollback, add_postcommit]
        end
      end

      let(:result) { 99 }

      it_behaves_like :transaction
    end

    context 'mapped' do
      subject do
        described_class.new do
          [99, add_rollback, add_postcommit]
        end.map { |x| x + 1 }
      end

      let(:result) { 100 }

      it_behaves_like :transaction
    end

    context 'binded' do
      subject do
        described_class.new do
          [99, add_rollback, add_postcommit]
        end.bind do |x|
          described_class.new do
            [x + 1]
          end
        end
      end

      let(:result) { 100 }

      it_behaves_like :transaction
    end

    context 'mixed' do
      subject do
        described_class.new do
          [99, add_rollback, add_postcommit]
        end.bind do |x|
          described_class.new do
            [x + 1, add_rollback, add_postcommit]
          end.map { |x| x * 3 }
        end.map { |x| x / 2 }
        .bind { |x| described_class.new { [x + 150, add_rollback, add_postcommit] } }
      end

      let(:result) { 300 }

      it_behaves_like :transaction
    end
  end
end
