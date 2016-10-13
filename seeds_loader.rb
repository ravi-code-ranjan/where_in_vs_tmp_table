require 'pg'
require 'yaml'

class SeedsLoader
  attr_reader :num_accounts, :num_requests, :db_connection

  def self.create_database
    drop_database
    name = config['database']['dbname']
    puts "Creating #{name} database ..."
    conn = ::PG.connect(config['database'].merge(dbname: 'postgres'))
    conn.exec "CREATE DATABASE #{name}"
    conn.close
  end

  def self.drop_database
    name = config['database']['dbname']
    puts "Droping #{name} database if exists ..."
    conn = ::PG.connect(config['database'].merge(dbname: 'postgres'))
    conn.exec "DROP DATABASE IF EXISTS #{name}"
    conn.close
  end

  def self.config
    @config ||=
      YAML.load(File.open(File.join(File.dirname(__FILE__), 'config.yml')))
  end

  def initialize(num_accounts, num_requests)
    @num_accounts = num_accounts
    @num_requests = num_requests
    @db_connection = ::PG.connect(config['database'])
  end

  def generate(with_index = false)
    drop_table
    create_table
    index_account_id if with_index

    puts 'Generating requests data ...'
    (1..num_requests).each_slice(100) do |slice|
      insert_records(slice.length)
    end

  rescue => error
    puts "Error: #{error.message}"
    puts error.backtrace.inspect
    puts "Droping 'requests' table ..."

    drop_table if db_connection
  end

  private

  def insert_records(num_records)
    inserts = Array.new(num_records) do
      "('#{rand_account_id}', '#{rand_request_date}', '#{rand_total}')"
    end
    db_connection.exec %{
      INSERT INTO "requests" ("account_id", "request_date", "total")
      VALUES #{inserts.join(', ')};
    }
  end

  def create_table
    puts "Creating 'requests' table ..."
    db_connection.exec %{
      CREATE TABLE IF NOT EXISTS "requests" (
        "id" serial primary key,
        "account_id" bigint NOT NULL,
        "request_date" date NOT NULL,
        "total" bigint DEFAULT 0 NOT NULL
      );
    }
  end

  # same as above, but add index on account_id column
  def index_account_id
    puts "Adding index to 'account_id' column ..."
    db_connection.exec %{
      CREATE INDEX ix_account_id_0 ON requests USING btree (account_id);
    }
  end

  def drop_table
    puts "Droping 'requests' table if exists ..."
    db_connection.exec 'DROP TABLE IF EXISTS "requests" CASCADE;'
  end

  def rand_account_id
    rand(1..num_accounts)
  end

  def rand_request_date
    "2015-11-#{rand(1..30)}"
  end

  def rand_total
    rand(100..10_001)
  end

  def config
    self.class.config
  end
end
