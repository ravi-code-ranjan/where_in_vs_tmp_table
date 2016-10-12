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
######################################################################

SeedsLoader.create_database

# generate seeds
sl = SeedsLoader.new(num_accounts, num_requests)
sl.generate(index_account_id)

query = Query.new(account_ids)

puts '=================================='
Benchmark.bm do |x|
  x.report('use_in_clause') { query.use_in_clause }
  x.report('use_join_tmp_table') { query.use_join_tmp_table }
end
puts '=================================='

sl.db_connection.close
query.db_connection.close
SeedsLoader.drop_database
