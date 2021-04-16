require 'dry-initializer'

class ConnectionProxy
  extend Forwardable
  extend Dry::Initializer

  option :host, default: proc { ENV["DB_HOST"] }
  option :user, default: proc { ENV["PGUSER"] }
  option :password, default: proc { ENV["PGPASSWORD"] }
  option :dbname, default: proc { 'postgres' }

  def_delegators :connection, :exec, :raw_exec, :close, :transaction

  def clean_exec(...)
    exec('DISCARD ALL')
    exec(...)
  end

  def connection
    @connection ||= PG.connect(options)
  end

  def options
    {user: user, password: password, host: host, dbname: dbname}
  end
end
