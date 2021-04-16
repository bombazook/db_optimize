require 'spec_helper'

RSpec.describe 'Simple index' do
  include_context 'prepare databases'

  context 'with user_id' do
    let(:raw){ LikesDB.new }
    let(:copy){ CopyDB.new }

    before :all do
      @copy.create_index table: 'likes', columns: 'user_id'
    end

    include_examples 'compare queries', :raw, :copy do
      let(:first_user_id) { connection.exec('SELECT * FROM likes LIMIT 1').getvalue(0, 0) }
      let(:query){ "SELECT COUNT(*) FROM likes WHERE user_id = #{first_user_id}" }
    end
  end

  context 'with post_id' do
    let(:raw){ LikesDB.new }
    let(:copy){ CopyDB.new }

    before :all do
      @copy.create_index table: 'likes', columns: 'post_id'
    end

    include_examples 'compare queries', :raw, :copy do
      let(:first_post_id) { connection.exec('SELECT * FROM likes LIMIT 1').getvalue(0, 1) }
      let(:query){ "SELECT COUNT(*) FROM likes WHERE post_id = #{first_post_id}" }
    end
  end
end
