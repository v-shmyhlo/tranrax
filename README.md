# TODO: Cleanup mess in README.md

# Tranrax
[![Build Status](https://travis-ci.org/v-shmyhlo/tranrax.svg?branch=master)](https://travis-ci.org/v-shmyhlo/tranrax)

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/tranrax`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tranrax'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tranrax

## Usage

More examples in "examples" foldes

### Write to a file

```ruby
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
```

```ruby
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
```

### Repo example

```ruby
User = Struct.new(:id, :name)

class UserRepo
  def initialize
    @records = []
  end

  def all
    @records
  end

  def create(record)
    @records << record
    record
  end

  def delete(id)
    @records = @records.reject { |record| record.id == id }
    nil
  end
end
```

```ruby
create_user = lambda do |repo, user|
  Tranrax::Transaction.new do
    result = repo.create(user)

    [result, -> { repo.delete(result.id) }]
  end
end

repo = UserRepo.new
repo.create(User.new(1, 'John'))

transaction = create_user.call(repo, User.new(2, 'Joe'))

transaction.transact do |result|
  puts result
  # => #<struct User id=2, name="Joe">
  puts repo.all.count
  # => 2

  raise 'Damn :('
end

puts repo.all.count
# => 1
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/v-shmyhlo/tranrax.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
