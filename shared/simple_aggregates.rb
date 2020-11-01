RSpec.shared_examples 'simple aggregates' do |raw_connection, copy_connection|
  let(:connection){ send(raw_connection) }
  let(:optimized_connection){ send(copy_connection) }
  let(:first_user_id) { connection.exec('SELECT * FROM likes LIMIT 1').getvalue(0, 0) }
  let(:query_1) { "SELECT COUNT(*) FROM likes WHERE user_id = #{first_user_id}" }
  let(:optimized_query) { query_1 }
  let(:performance_gain_times) { 100 }

  it 'shows what to optimize' do
    tuples = connection.exec("EXPLAIN (ANALYZE, VERBOSE, BUFFERS) #{query_1}")
    tuples.ntuples.times do |i|
      puts tuples.getvalue(i, 0)
    end
  end

  it 'shows what was optimized' do
    tuples = optimized_connection.exec("EXPLAIN (ANALYZE, VERBOSE, BUFFERS) #{optimized_query}")
    tuples.ntuples.times do |i|
      puts tuples.getvalue(i, 0)
    end
  end

  it "runs user_id query with many times better performance" do
    expect do
      optimized_connection.exec(optimized_query)
    end.to (perform_faster_than do
      connection.exec(query_1)
    end).at_least(performance_gain_times).times
  end

  it "returns same results" do
    default_tuples = connection.exec(query_1)
    optimized_tuples = optimized_connection.exec(optimized_query)
    expect(default_tuples.values).to be_eql(optimized_tuples.values)
  end
end
