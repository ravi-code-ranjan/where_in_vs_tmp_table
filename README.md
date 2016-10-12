# Compare WHERE IN with TEMP TABLE
This benchmark aims to compare PostgreSQL queries that use `WHERE IN (...)` with `TEMP TABLE` in Ruby.

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
The 1st approach uses `WHERE IN (...)` clause, where the `(...)` is a list of `account_ids`:
```sql
SELECT account_id, SUM(total) AS total_requests
FROM requests r
WHERE r.account_id IN (1,2,3,4, ...)
GROUP BY r.account_id
```

## Approach 2: Use 'TEMP TABLE'
The 2nd approach creates a `TEMP TABLE` called `tmp_accounts`, which only includes those selected `account_ids`:
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

3. Run `bundle exec ruby benchmark.rb`.

The code will create the database, create the `requests` table, seed random data, and then run the benchmark. After the benchmark, it will drop the database.

By default, the code will generate `500,000` rows of requests for `5,000` account ids. And it will randomly choose `50%` of the account ids for the query. You can tune these settings inside [benchmark.rb](benchmark.rb).

## Benchmark Results
My laptop specs: Macbook Pro 2.2GHz Intel Core i7, 16GB Memory, 250 GB SSD

500,000 rows of requests with 5,000 account ids, and select 50% of the account ids for the query.

When the index on `account_id` column is disabled, by setting the variable `index_account_id` to `false` in `benchmark.rb`:
```bash
user                system     total      real
use_in_clause       0.010000   0.000000   0.010000 (  6.152411)
use_join_tmp_table  0.000000   0.000000   0.000000 (  0.223172)
```

When `index_account_id = true`, the results are:
```bash
user                system     total      real
use_in_clause       0.000000   0.000000   0.000000 (  0.246094)
use_join_tmp_table  0.000000   0.000000   0.000000 (  0.205016)
```
