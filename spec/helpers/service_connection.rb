require 'singleton'

class ServiceConnection < ConnectionProxy
  include Singleton

  def clone_db origin, dbname: [origin.dbname, "copy"].join("_")
    kill_connections_for origin.dbname
    kill_connections_for dbname
    exec "CREATE DATABASE #{dbname} WITH TEMPLATE #{origin.dbname}"
  end

  def create_database dbname
    exec "CREATE DATABASE #{dbname}"
  end

  def drop_database dbname
    kill_connections_for dbname
    exec("DROP DATABASE #{dbname}")
  end

  private

  def kill_connections_for dbname
    exec %{
      SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE pg_stat_activity.datname = '#{dbname}'
      AND pid <> pg_backend_pid();
    }
  end
end
