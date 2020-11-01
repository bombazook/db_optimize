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

  context "adding row counts table and trigger (can be updated to support 'UPDATE' TG_OP)" do
    include_context "db copy"

    before :all do
      copy.raw_exec 'CREATE TABLE
        rowcount (
          table_name text NOT NULL,
          field_name text NOT NULL,
          field_value text NOT NULL,
          total_rows bigint,
          PRIMARY KEY (table_name, field_name, field_value)
        );'
      field_name = 'user_id'
      copy.raw_exec %(
        CREATE OR REPLACE FUNCTION count_#{field_name}_rows()
          RETURNS TRIGGER AS
          '
            BEGIN
              IF TG_OP = ''INSERT'' THEN
                UPDATE rowcount
                  SET total_rows = total_rows + 1
                  WHERE table_name = TG_TABLE_NAME
                  AND field_name = ''#{field_name}''
                  AND field_value = NEW.#{field_name};
              ELSIF TG_OP = ''DELETE'' THEN
                UPDATE rowcount
                  SET total_rows = total_rows - 1
                  WHERE table_name = TG_TABLE_NAME
                  AND field_name = ''#{field_name}''
                  AND field_value = OLD.#{field_name};
              END IF;
              RETURN NULL;
            END;
          ' LANGUAGE plpgsql;
      )
      copy.transaction do
        copy.raw_exec %(
          LOCK TABLE likes IN SHARE ROW EXCLUSIVE MODE;
          create TRIGGER countrows AFTER INSERT OR DELETE on likes FOR EACH ROW EXECUTE PROCEDURE count_#{field_name}_rows();
          DELETE FROM rowcount WHERE table_name = 'likes';
          INSERT INTO rowcount (table_name, field_name, field_value, total_rows)
          SELECT
            'likes' as table_name,
            '#{field_name}' as field_name,
            #{field_name},
            COUNT(#{field_name})
          FROM likes GROUP BY #{field_name};
        )
      end
    end

    include_examples 'simple aggregates', :raw, :copy, 1000 do
      let(:optimized_query){  "SELECT total_rows FROM rowcount WHERE table_name = 'likes' AND field_name = 'user_id' AND field_value = #{first_user_id}::text" }
      let(:performance_gain_times) { 200 }
    end

  end
end
