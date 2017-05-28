# frozen_string_literal: true

require 'securerandom'
require 'tranrax'
require 'fileutils'

# write_file returns Transaction which writes to a file
# and restores original content (or removes file) in case of failure
write_file = lambda do |file_name, contents|
  Tranrax::Transaction.new do
    file_exists = File.exist?(file_name)

    operations =
      if file_exists
        tmpfile_name = SecureRandom.hex
        FileUtils.mv(file_name, tmpfile_name)

        [
          -> { FileUtils.mv(tmpfile_name, file_name) }, # rollback logic
          -> { FileUtils.rm(tmpfile_name) } # postcommit logic (cleanup on success)
        ]
      else
        [
          -> { FileUtils.rm(file_name) } # only rollback, no postcommit
        ]
      end

    File.write(file_name, contents)

    # returns result of operation ("whatever" in this case), rollback operation and postcommit operation
    ['whatever', *operations]
  end
end

# nothing is done at this point
transaction = write_file.call('test_1.txt', 'hello world')

# run transaction
transaction.transact do |_result|
  # at this point file is written and you can observe changes
  # result == "whatever"

  sleep 3
  raise 'Damn :('
end
# rollback takes places, original file restored

# you can compose transactions
transaction = write_file
  .call('test_1.txt', 'hello world')
  .map { |result| "Result of first operation is \"#{result}\"" }
  .bind { |result| write_file.call('test_2.txt', result) }

# everything is rolled back
transaction.transact do
  sleep 3
  raise 'Damn :('
end
