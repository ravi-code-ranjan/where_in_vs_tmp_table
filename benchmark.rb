require 'benchmark'
require_relative './seeds_loader.rb'
require_relative './query.rb'

GC.disable

#####################################################################
# Settings
num_accounts = 5_000
num_requests = 500_000
index_account_id = true

# choose 50% ids for bechmark
account_ids = (1..num_accounts).to_a.sample((num_accounts * 0.5).to_i)

iterations = 1
######################################################################

SeedsLoader.create_database

# generate seeds
sl = SeedsLoader.new(num_accounts, num_requests)
sl.generate(index_account_id)

query = Query.new(account_ids)

puts 'Running benchmarks ...'
puts
puts '=================================='
if index_account_id
  puts 'Results with index on account_id'
else
  puts 'Results without index on account_id'
end
Benchmark.bm do |x|
  x.report('use_where_any') { iterations.times { query.use_where_any } }
  x.report('use_where_in') { iterations.times { query.use_where_in } }
  x.report('use_tmp_table') { iterations.times { query.use_tmp_table } }
end
puts '=================================='

sl.db_connection.close
query.db_connection.close
SeedsLoader.drop_database
puts 'Done'
