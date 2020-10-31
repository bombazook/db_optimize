require './spec_helper'

USERS_COUNT = 10_000
POSTS_COUNT = 10_000
LIKES_COUNT = 1_000_000

RSpec.describe 'sql select speedup' do
  include RSpec::Benchmark::Matchers
  include_context 'likes db' do
    ['likes', 'users', 'posts'].each do |i|
      let("#{i}_count"){ Object.const_get "#{i.capitalize}_COUNT" }
    end
  end

  context 'adding index' do
    include_context "db copy"

    before :all do
      copy.exec 'CREATE INDEX user_id_index ON likes (user_id)'
    end

    include_examples 'simple aggregates', :raw, :copy
  end

  context 'adding materialized view' do
    include_context "db copy"

    before :all do
      copy.exec 'CREATE INDEX user_id_index ON likes (user_id)'
    end

    include_examples 'simple aggregates', :raw, :copy
  end
end
