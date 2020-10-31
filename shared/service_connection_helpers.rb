module ServiceConnectionHelpers
  def service_connection
    @service_connection ||= begin
      PG.connect(**default_credentials.merge(dbname: 'postgres'))
    end
  end

  def admin_user
    [ENV["PGUSER"], 'admin', 'root', `echo $USER`.chomp].each do |u|
      PG.connect(dbname: 'postgres', user: u, password: admin_password).close
      return u
    rescue PG::ConnectionBad
    end
    raise "Please specify correct service connection user name/password"
  end

  def admin_password
    ENV["PGPASSWORD"]
  end

  def default_credentials
    {user: admin_user, password: admin_password}
  end

  def kill_connections dbname
    service_connection.exec %(
      SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE pg_stat_activity.datname = '#{dbname}'
      AND pid <> pg_backend_pid();
    )
  end
end
