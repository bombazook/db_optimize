class CopyDB < ConnectionProxy
  option :dbname, default: proc { "likes_db_test_copy" }

  def create_index table:, columns:
    index_name = [columns, 'index'].flatten.join('_')
    fields_list = [columns].flatten.join(', ')
    exec "CREATE INDEX #{index_name} ON #{table} (#{fields_list})"
  end

  def create_rowcount_table
    clone.exec %{
      CREATE TABLE
      rowcount (
        table_name text NOT NULL,
        field_name text NOT NULL,
        field_value text NOT NULL,
        total_rows bigint,
        PRIMARY KEY (table_name, field_name, field_value)
      );
    }
  end

  def create_rowcount_update_trigger table: 'likes', column: 'user_id'
    clone.exec %{
      CREATE OR REPLACE FUNCTION count_#{table}_#{column}_rows()
      RETURNS TRIGGER AS
      '
        BEGIN
          IF TG_OP = ''INSERT'' THEN
            UPDATE rowcount
              SET total_rows = total_rows + 1
              WHERE table_name = TG_TABLE_NAME
              AND field_name = ''#{column}''
              AND field_value = NEW.#{column};
          ELSIF TG_OP = ''DELETE'' THEN
            UPDATE rowcount
              SET total_rows = total_rows - 1
              WHERE table_name = TG_TABLE_NAME
              AND field_name = ''#{column}''
              AND field_value = OLD.#{column};
          END IF;
          RETURN NULL;
        END;
      ' LANGUAGE plpgsql;
    }
  end

  def install_rowcount_update_trigger_on_table table: 'likes', column: 'user_id'
    connection = clone
    connection.transaction do
      connection.exec %{
        LOCK TABLE #{table} IN SHARE ROW EXCLUSIVE MODE;
        create TRIGGER count_#{table}_#{column}_rows AFTER INSERT OR DELETE on #{table} FOR EACH ROW EXECUTE PROCEDURE count_#{table}_#{column}_rows();
        DELETE FROM rowcount WHERE table_name = '#{table}' AND field_name = '#{column}';
        INSERT INTO rowcount (table_name, field_name, field_value, total_rows)
          SELECT
            '#{table}' as table_name,
            '#{column}' as field_name,
            #{column},
            COUNT(#{column})
        FROM #{table} GROUP BY #{column};
      }
    end
  end
end
