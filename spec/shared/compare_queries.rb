RSpec.shared_examples 'compare queries' do |raw_connection, copy_connection|
  include RSpec::Benchmark::Matchers
  let(:connection){ send(raw_connection) }
  let(:optimized_connection){ send(copy_connection) }
  let(:query) { raise("Please specify original sql query") }
  let(:optimized_query) { query }

  it '↑ shows what should be optimized' do
    tuples = connection.clean_exec("EXPLAIN (ANALYZE, VERBOSE, BUFFERS) #{query}")
    tuples.ntuples.times do |i|
      puts tuples.getvalue(i, 0).cyan
    end
  end

  it '↑ shows what was optimized' do
    tuples = optimized_connection.clean_exec("EXPLAIN (ANALYZE, VERBOSE, BUFFERS) #{optimized_query}")
    tuples.ntuples.times do |i|
      puts tuples.getvalue(i, 0).cyan
    end
  end

  it "optimized query has many times better performance" do
    expect do
      optimized_connection.exec(optimized_query)
    end.to (perform_faster_than do
      connection.exec(query)
    end)
  end

  it "returns same results" do
    default_tuples = connection.exec(query)
    optimized_tuples = optimized_connection.exec(optimized_query)
    expect(default_tuples.values).to be_eql(optimized_tuples.values)
  end
end
