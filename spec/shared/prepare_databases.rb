RSpec.shared_context "prepare databases" do
  before :all do
    @dbname = 'likes_db_test'
    @db_copy_name = 'likes_db_test_copy'
    @service_connection = ServiceConnection.instance
    begin
      @service_connection.create_database @dbname
      row_counts = ROW_COUNTS
      LikesDB.new.build_data counts: row_counts
    rescue PG::DuplicateDatabase
      puts "db #{@dbname} already exists, skipping...".yellow
    end
    db = LikesDB.new
    begin
      @service_connection.clone_db db, dbname: @db_copy_name
    rescue PG::DuplicateDatabase
      puts "db #{@db_copy_name} already exists, skipping...".yellow
    end
    @copy = CopyDB.new
  end

  around :each do |example|
    @copy.exec 'BEGIN'
    example.run
    @copy.exec 'ROLLBACK'
  end
end
