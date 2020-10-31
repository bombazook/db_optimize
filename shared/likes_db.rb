RSpec.shared_context "likes db" do
  def db_name
    @db_name ||= "likes_db_test"
  end

  def raw
    @raw ||= DbCover.new(**default_credentials.merge(dbname: db_name))
  end

  def load_data
    (likes_count || 1_000_000).times do
      user_id = rand(USERS_COUNT || 10_000)
      post_id = rand(POSTS_COUNT || 10_000)
      created_at = (Time.now + rand(-78_840_000..0))
      updated_at = created_at + rand(3600)
      created_at_iso = created_at.strftime('%F %T %:z')
      updated_at_iso = updated_at.strftime('%F %T %:z')
      exec "INSERT into likes VALUES (#{user_id}, #{post_id}, '#{created_at_iso}', '#{updated_at_iso}')"
    end
  end

  before :all do
    kill_connections db_name
    begin
      service_connection.exec "CREATE DATABASE #{db_name}"
    rescue PG::DuplicateDatabase
      service_connection.exec "DROP DATABASE #{db_name}"
      retry
    end
    raw.exec %(
      CREATE TABLE likes (
        user_id     integer,
        post_id     integer,
        created_at  timestamp with time zone,
        updated_at timestamp with time zone
      );
    )
    raw.load_or_build_table 'likes', 'likes_data.csv', &method(:load_data)
  end

  after :all do
    raw.close
    service_connection.exec "DROP DATABASE #{db_name}"
    service_connection.close
  end
end
