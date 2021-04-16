require 'spec_helper'

RSpec.describe 'Multicolumn query' do
  include_context 'prepare databases'

  context 'with user_id' do
    let(:raw){ LikesDB.new }
    let(:copy){ CopyDB.new }

    before :all do
      @first_user_id = @copy.exec('SELECT * FROM pending_posts LIMIT 1').getvalue(0, 1)
      @copy.exec %{
          CREATE MATERIALIZED VIEW pending_posts_for_user_#{@first_user_id}
          AS SELECT * FROM pending_posts
          WHERE user_id <> #{@first_user_id}
            AND NOT approved
            AND NOT banned
            AND pending_posts.id NOT IN(
              SELECT pending_post_id FROM viewed_posts
                WHERE user_id = #{@first_user_id})
        }
    end

    before :all do
      puts <<-HEREDOC.gray
        even though we created materialized view, 
        there is no significant speedup because of huge results dataset
        I see no possible query optimizations
        Also tried: LEFT JOIN ... WHERE <right column> = NULL, NOT EXISTS and different btree multicolumn indexes 
      HEREDOC
    end

    include_examples 'compare queries', :raw, :copy do
      let(:first_user_id) { @first_user_id }
      let(:query) do
        %{
          SELECT * FROM pending_posts
            WHERE user_id <> #{first_user_id}
              AND NOT approved
              AND NOT banned
              AND pending_posts.id NOT IN(
                SELECT pending_post_id FROM viewed_posts
                  WHERE user_id = #{first_user_id})
        }
      end
      let(:optimized_query) do
        %{
          SELECT * FROM pending_posts_for_user_#{first_user_id}
        }
      end
    end
  end
end
