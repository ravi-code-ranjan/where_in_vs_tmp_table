# Compare WHERE IN with TEMP TABLE
This benchmark aims to compare PostgreSQL queries among `WHERE IN (...)`, `WHERE ANY (...)` and `TEMP TABLE` in Ruby.

Blog post: http://stevenyue.com/blogs/build-sql-queries-with-temporary-table-vs-where-in/

## Test Case
Given a `requests` table with schema like this:

```sql
CREATE TABLE "requests" (
  "id" serial primary key,
  "account_id" bigint NOT NULL,
  "request_date" date NOT NULL,
  "total" bigint DEFAULT 0 NOT NULL
);
```

Write a sql query that returns the sum of `total`, group by `account_id` for a given list of `account_ids`.

## Approach 1: Use 'WHERE IN'
This approach uses `WHERE IN (...)` clause, where the `(...)` is a list of `account_ids`:
```sql
SELECT account_id, SUM(total) AS total_requests
FROM requests r
WHERE r.account_id IN (1,2,3,4, ...)
GROUP BY r.account_id
```

## Approach 2: Use 'WHERE ANY'
This approach uses `WHERE ANY ( VALUES (), ... )` clause, where the ` VALUES (), () ...` contains values from `account_ids`:
```sql
SELECT account_id, SUM(total) AS total_requests
FROM requests r
WHERE r.account_id = ANY ( VALUES (1), (2), (3), ... )
GROUP BY r.account_id
```

## Approach 3: Use 'TEMP TABLE'
This approach creates a `TEMP TABLE` called `tmp_accounts`, which only includes those selected `account_ids`:
```sql
CREATE TEMP TABLE tmp_accounts (
  "account_id" INT8,
  CONSTRAINT "id_pkey" PRIMARY KEY ("account_id")
)
ON COMMIT DROP;
```
and then uses `INNER JOIN` to do the filtering and get the results:
```sql
SELECT r.account_id, SUM(total) AS total_requests
FROM requests r
INNER JOIN tmp_accounts ON tmp_accounts.account_id = r.account_id
GROUP BY r.account_id
```
Note that the temp table will get dropped after the transaction.

## Run Benchmark
1. Rename `config.yml.example` to `config.yml`, and update the database configuration in the file accordingly.

2. Run `bundle install`

3. Modify default settings in `benchmark.rb`

4. Run `bundle exec ruby benchmark.rb`.

The code will create the database, create the `requests` table, seed random data, and then run the benchmark, and after that, it will drop the database.

By default, the code will generate `500,000` rows of requests for `5,000` account ids. Then it will randomly choose `50%` of the account ids for the queries, and run each query only `1` time. You can tune these settings inside [benchmark.rb](benchmark.rb).

## Benchmark Results
Hardware specs: Macbook Pro 2.2GHz Intel Core i7, 16GB Memory, 250 GB SSD

Database: PostgreSQL 9.4.5

Seeds: 500,000 rows of requests, 5,000 account ids, and randomly choose 50% of the account ids.

When the index on `account_id` column is enabled, by setting the variable `index_account_id` to `true` in `benchmark.rb`:
```bash
                    user     system      total        real
use_where_in    0.000000   0.000000   0.000000 (  0.242052)
use_where_any   0.010000   0.000000   0.010000 (  0.219573)
use_tmp_table   0.000000   0.000000   0.000000 (  0.193532)
```

When there is no index on `account_id`, the results are:
```bash
                    user     system      total        real
use_where_in    0.000000   0.000000   0.000000 (  6.290538)
use_where_any   0.000000   0.000000   0.000000 (  0.192422)
use_tmp_table   0.000000   0.000000   0.000000 (  0.193068)
```
