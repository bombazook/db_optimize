require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'rspec'
  gem 'pg'
  gem 'byebug'
  gem 'rspec-benchmark'
end

USERS_COUNT = 10_000
POSTS_COUNT = 10_000
LIKES_COUNT = 1_000_000

RSpec.shared_examples "queries" do
  let(:first_user_id){ connection.exec("SELECT * FROM likes LIMIT 1").getvalue 0,1 }
  let(:query_1){ "SELECT COUNT(*) FROM likes WHERE user_id = #{first_user_id};" }

  it "shows what to optimize" do
    tuples = connection.exec("EXPLAIN ANALYZE #{query_1}")
    tuples.ntuples.times do |i|
      puts tuples.getvalue(i, 0)
    end
  end

  it "shows what was optimized" do
    tuples = optimized_connection.exec("EXPLAIN ANALYZE #{query_1}")
    tuples.ntuples.times do |i|
      puts tuples.getvalue(i, 0)
    end
  end

  it "runs user_id query with 100 times better performance" do
    expect do
      optimized_connection.exec(query_1)
    end.to (perform_faster_than do
      connection.exec(query_1)
    end).at_least(100).times
  end
end

RSpec.describe "sql select speedup" do
  include RSpec::Benchmark::Matchers

  before :all do
    @db_name = "optimize_select"
    @optimized_db_name = [@db_name, "optimized"].join '_'
    @service_connection = PG.connect(dbname: 'postgres', user: 'admin')
    begin
      @service_connection.exec "DROP DATABASE #{@db_name};"
      @service_connection.exec "DROP DATABASE #{@optimized_db_name}"
    rescue PG::InvalidCatalogName
    end
    @service_connection.exec "CREATE DATABASE #{@db_name};"
    @service_connection.exec "CREATE DATABASE #{@optimized_db_name};"
    @connection = PG.connect dbname: @db_name, user: 'admin'
    @optimized_connection = PG.connect dbname: @optimized_db_name, user: 'admin'
  end

  def load_data connection, path
    connection.exec("COPY likes (user_id, post_id, created_at, updated_at) FROM STDIN WITH CSV")
    file = File.open(path, 'r')
    while !file.eof?
      connection.put_copy_data(file.readline)
    end
    connection.put_copy_end
  end

  def build_data connection, &block
    yield connection if block_given?
  end

  def dump_data connection, path
    File.open(path, 'w') do |f|
      connection.copy_data "COPY likes TO STDOUT CSV" do
        while row=connection.get_copy_data
          f.puts row
        end
      end
    end
  end

  def insert_data connection, file='likes_data.csv', &block
    path = File.join(__dir__, file)
    if File.exists?(path)
      load_data connection, path
    else
      build_data connection, &block
      dump_data connection, path
    end
  end

  before :all do
    # likes (user_id: integer, post_id: integer, created_at: datetime, updated_at: datetime)
    query = %(
      CREATE TABLE likes (
        user_id     integer,
        post_id     integer,
        created_at  timestamp with time zone,
        updated_at timestamp with time zone
      );
    )
    @connection.exec query
    @optimized_connection.exec query
    build_data = -> connection do
      LIKES_COUNT.times do
        user_id = rand(USERS_COUNT)
        post_id = rand(POSTS_COUNT)
        created_at = (Time.now + rand(-78840000..0))
        updated_at = created_at + rand(3600)
        created_at_iso = created_at.strftime("%F %T %:z")
        updated_at_iso = updated_at.strftime("%F %T %:z")
        connection.exec "INSERT into likes VALUES (#{user_id}, #{post_id}, '#{created_at_iso}', '#{updated_at}')"
      end
    end
    insert_data @connection, &build_data
    insert_data @optimized_connection, &build_data
  end

  after :all do
    @connection.close
    @optimized_connection.close
    @service_connection.exec "DROP DATABASE #{@db_name};"
    @service_connection.exec "DROP DATABASE #{@optimized_db_name}"
  end

  context "adding index" do
    before :all do
      @optimized_connection.exec "CREATE INDEX user_id_index ON likes (user_id)"
    end

    after :all do
      @optimized_connection.exec "DROP INDEX user_id_index"
    end

    include_examples "queries" do
      let(:connection){ @connection }
      let(:optimized_connection){ @optimized_connection }
    end
  end
end
