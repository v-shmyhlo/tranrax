require 'tranrax'

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
