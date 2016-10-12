class Query
  attr_reader :db_connection, :account_ids, :from, :to

  def initialize(account_ids)
    @db_connection = ::PG.connect(config['database'])
    @account_ids = account_ids
  end

  def use_join_tmp_table
    db_connection.transaction do
      db_connection.exec(create_temp_table)
      db_connection.copy_data('COPY tmp_accounts (account_id) FROM STDIN') do
        account_ids_inserts.each { |chunk| db_connection.put_copy_data(chunk) }
      end
      db_connection.exec query_requests_with_join_table
    end
  end

  def use_in_clause
    db_connection.exec query_requests
  end

  private

  def account_ids_inserts
    chunk_size = 100
    account_ids.each_slice(chunk_size).map { |s| s.join("\n") << "\n" }
  end

  # get sum of requests in a date range for certain accounts
  # this query uses `IN` clause
  def query_requests
    %{
      SELECT account_id, SUM(total) AS total_requests
      FROM requests r
      WHERE r.account_id IN (#{account_ids.join(',')})
      GROUP BY r.account_id
    }
  end

  # query using JOIN a temp table
  def query_requests_with_join_table
    %{
      SELECT r.account_id, SUM(total) AS total_requests
      FROM requests r
      INNER JOIN tmp_accounts ON tmp_accounts.account_id = r.account_id
      GROUP BY r.account_id
    }
  end

  def create_temp_table
    %{
      CREATE TEMP TABLE tmp_accounts (
        "account_id" INT8,
        CONSTRAINT "id_pkey" PRIMARY KEY ("account_id")
      )
      ON COMMIT DROP;
    }
  end

  def config
    @config ||=
      YAML.load(File.open(File.join(File.dirname(__FILE__), 'config.yml')))
  end
end
