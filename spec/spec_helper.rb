require 'delegate'
require 'forwardable'
require 'rubygems'
require 'bundler'
Bundler.require(:default)

Dir[File.join(__dir__, 'helpers', '*.rb')].sort.each { |file| require file }
Dir[File.join(__dir__, 'shared', '*.rb')].sort.each { |file| require file }

FORCE_REBUILD = (ENV["FORCE_REBUILD"] == 'true')
ROW_COUNTS = ENV["ROW_COUNTS"]&.to_i || 1_000_000

RSpec.configure do |c|
  c.before :suite do
    if FORCE_REBUILD
      puts "FORCE_REBUILD is set, rebuilding db"
      ServiceConnection.instance.drop_database 'likes_db_test'
    end
  end

  c.after :all do
    ServiceConnection.instance.drop_database 'likes_db_test_copy'
  end
end

