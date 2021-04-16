class LikesDB < ConnectionProxy
  option :dbname, default: proc { "likes_db_test" }

  def build_data counts: nil
    counts ||= 1_000_000
    create_likes
    populate_likes count: counts
    create_pending_posts
    populate_pending_posts count: counts
    create_viewed_posts
    populate_viewed_posts count: counts
  end

  def create_likes
    puts "Creating likes table".green
    exec %{
      CREATE TABLE likes (
        user_id     integer,
        post_id     integer,
        created_at  timestamp with time zone,
        updated_at timestamp with time zone
      );
    }
  end

  def create_pending_posts
    puts "Creating pending_posts table".green
    exec %{
      CREATE TABLE pending_posts (
        id                SERIAL PRIMARY KEY,
        user_id           integer NOT NULL,
        approved          boolean NOT NULL DEFAULT FALSE,
        banned            boolean NOT NULL DEFAULT FALSE
      );
    }
  end

  def create_viewed_posts
    puts "Creating viewed_posts table".green
    exec %{
      CREATE TABLE viewed_posts (
        pending_post_id   integer references pending_posts(id),
        user_id           integer NOT NULL,
        PRIMARY KEY (pending_post_id, user_id)
      );
    }
  end

  def populate_likes count: 1_000_000
    puts "Creating #{count} likes".green
    exec %{
      WITH data as (
        WITH root as(
          select (random()*1000000)::int as post_id,
                (random()*10000)::int as user_id,
                NOW() - random()*(INTERVAL '5 years') as created_at
                FROM generate_series(1, #{count})
        )
        SELECT root.*, root.created_at + random()*(INTERVAL '3 days') as updated_at from root
      ) INSERT into likes (SELECT * FROM data);
    }
  end

  def populate_pending_posts count: 1_000_000
    puts "Creating #{count} pending_posts".green
    exec %{
      INSERT into pending_posts (user_id, approved, banned)
      SELECT (random()*10000)::int as user_id,
            (random() > 0.5) as approved,
            (random() > 0.5) as banned
      FROM generate_series(1, #{count})
    }
  end

  def populate_viewed_posts count: 1_000_000
    puts "Creating #{count} viewed_posts".green
    exec %{
      INSERT into viewed_posts (pending_post_id, user_id)
      SELECT generate_series(1, #{count}) as pending_post_id,
            (random()*10000)::int as user_id; 
    }
  end
end
