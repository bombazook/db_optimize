require 'spec_helper'

RSpec.describe 'Multicolumn index' do
  include_context 'prepare databases'

  before :all do
    @copy.create_index table: 'likes', columns: ['user_id', 'post_id']
  end

  context 'with user_id and post_id' do
    let(:raw){ LikesDB.new }
    let(:copy){ CopyDB.new }

    include_examples 'compare queries', :raw, :copy do
      let(:user_id) { connection.exec('SELECT * FROM likes LIMIT 1').getvalue(0, 0) }
      let(:post_id) { connection.exec('SELECT * FROM likes LIMIT 1').getvalue(0, 1) }
      let(:query) { "SELECT * FROM likes WHERE user_id = #{user_id} AND post_id = #{post_id}" }
    end
  end
end
