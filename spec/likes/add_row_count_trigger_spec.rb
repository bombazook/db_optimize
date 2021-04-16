require 'spec_helper'

RSpec.describe 'Rowcount trigger' do
  include_context 'prepare databases'

  before :all do
    @copy.create_rowcount_table
  end

  let(:raw){ LikesDB.new }
  let(:copy){ CopyDB.new }

  context "on user_id column" do
    before :all do
      @copy.create_rowcount_update_trigger table: 'likes', column: 'user_id'
      @copy.install_rowcount_update_trigger_on_table table: 'likes', column: 'user_id'
    end

    include_examples 'compare queries', :raw, :copy do
      let(:first_user_id) { connection.exec('SELECT * FROM likes LIMIT 1').getvalue(0, 0) }
      let(:query){ "SELECT COUNT(*) FROM likes WHERE user_id = #{first_user_id}" }
      let(:optimized_query) do
        "SELECT total_rows FROM rowcount WHERE table_name = 'likes' AND field_name = 'user_id' AND field_value = #{first_user_id}::text"
      end
    end
  end

  context "on post_id column" do
    before :all do
      @copy.create_rowcount_update_trigger table: 'likes', column: 'post_id'
      @copy.install_rowcount_update_trigger_on_table table: 'likes', column: 'post_id'
    end

    include_examples 'compare queries', :raw, :copy do
      let(:first_post_id) { connection.exec('SELECT * FROM likes LIMIT 1').getvalue(0, 1) }
      let(:query){ "SELECT COUNT(*) FROM likes WHERE post_id = #{first_post_id}" }
      let(:optimized_query) do
        "SELECT total_rows FROM rowcount WHERE table_name = 'likes' AND field_name = 'post_id' AND field_value = #{first_post_id}::text"
      end
    end
  end
end
