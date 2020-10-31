require 'bundler/inline'
require 'delegate'

gemfile do
  source 'https://rubygems.org'
  gem 'rspec'
  gem 'pg'
  gem 'byebug'
  gem 'rspec-benchmark'
end

Dir[File.join(__dir__, 'shared', '*.rb')].sort.each { |file| require file }

RSpec.configure do |c|
  c.include ServiceConnectionHelpers
end

class DbCover < SimpleDelegator
  def initialize *args
    super(PG.connect(*args))
  end

  def exec *args
    super('DISCARD ALL')
    super
  end

  def dump_table(table, path)
    File.open(path, 'w') do |f|
      copy_data "COPY #{table} TO STDOUT CSV" do
        while row = get_copy_data
          f.puts row
        end
      end
    end
  end

  def load_table(table, path)
    exec("COPY #{table} (user_id, post_id, created_at, updated_at) FROM STDIN WITH CSV")
    file = File.open(path, 'r')
    put_copy_data(file.readline) until file.eof?
    put_copy_end
  end

  def load_or_build_table table, path, dump_on_build: true
    if File.exist?(path)
      load_table table, path
    elsif block_given?
      yield self
      dump_table table, path if dump_on_build
    else
      raise "Provide existing table data csv or block to build it"
    end
  end
end
