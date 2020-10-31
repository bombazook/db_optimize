RSpec.shared_context "db copy" do
  def db_copy_name
    @db_copy_name ||= [db_name, "copy"].join "_"
  end

  def copy
    @copy ||= DbCover.new(**default_credentials.merge(dbname: db_copy_name))
  end

  before :all do
    kill_connections db_name
    kill_connections db_copy_name
    begin
      service_connection.exec "CREATE DATABASE #{db_copy_name} WITH TEMPLATE #{db_name}"
    rescue PG::DuplicateDatabase
      service_connection.exec "DROP DATABASE #{db_copy_name}"
      retry
    end
    raw.reset
  end

  after :all do
    copy.close
    service_connection.exec "DROP DATABASE #{db_copy_name}"
  end
end
