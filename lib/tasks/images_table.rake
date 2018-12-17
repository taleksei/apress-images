namespace :images_table do
  task upgrade: :environment do
    connection = ActiveRecord::Base.connection

    connection.transaction do
      unless connection.column_exists?(:images, :processing)
        puts 'Adding processing column...'
        connection.add_column(:images, :processing, :boolean)
      end

      unless connection.column_exists?(:images, :node)
        puts 'Adding node column...'
        connection.add_column(:images, :node, :integer)
      end
    end

    puts 'Set default processing field...'

    Apress::Images::Image.where(processing: nil).find_in_batches(batch_size: 2_000) do |batch|
      Apress::Images::Image.update_all({processing: false}, {id: batch.map(&:id)})
    end

    puts 'Alter processing column...'

    connection.execute <<-SQL.strip_heredoc
      ALTER TABLE "images" ALTER COLUMN "processing" SET DEFAULT false;
      ALTER TABLE "images" ALTER COLUMN "processing" SET NOT NULL;
    SQL

    puts 'Set default node field...'

    Apress::Images::Image.where(node: nil).find_in_batches(batch_size: 2_000) do |batch|
      Apress::Images::Image.update_all({node: 0}, {id: batch.map(&:id)})
    end

    puts 'Alter node column...'

    connection.execute <<-SQL.strip_heredoc
      ALTER TABLE "images" ALTER COLUMN "node" SET DEFAULT 0;
      ALTER TABLE "images" ALTER COLUMN "node" SET NOT NULL;
    SQL

    if connection.index_exists?(:images, [:subject_type, :subject_id])
      puts 'Upgrade indexes...'
      puts 'Normalize images positions before index creation...'

      sub_query = Apress::Images::Image.
        group(:subject_id, :subject_type).
        select('MIN(id) AS id, subject_id, subject_type').
        to_sql

      Apress::Images::Image.
        from("(#{sub_query}) AS #{Apress::Images::Image.quoted_table_name}").
        find_each(batch_size: 2_000) do |image|
        Apress::Images::Image.normalize_positions(image.subject_id, image.subject_type)
      end

      puts 'Create index...'

      connection.execute <<-SQL.strip_heredoc
        CREATE UNIQUE INDEX CONCURRENTLY "idx_images_on_subject_position"
          ON "images" (subject_type, subject_id, "position");
      SQL

      puts 'Set constraints...'

      connection.execute <<-SQL.strip_heredoc
        ALTER TABLE "images" ADD CONSTRAINT "images_subject_position"
          UNIQUE USING INDEX "idx_images_on_subject_position" DEFERRABLE INITIALLY DEFERRED;
      SQL

      puts 'Drop old index...'

      connection.execute <<-SQL.strip_heredoc
        DROP INDEX CONCURRENTLY #{connection.index_name(:images, [:subject_type, :subject_id])};
      SQL
    end
  end

  desc 'Rename updated_at to img_updated_at column'
  task rename_updated_at: :environment do
    logger = Logger.new(STDOUT)
    logger.formatter = Logger::Formatter.new
    ActiveRecord::Base.logger = logger

    ActiveRecord::Base.on(:direct).connection.execute <<-SQL.strip_heredoc
      BEGIN;
        SET LOCAL statement_timeout TO '10s';
        ALTER TABLE images RENAME COLUMN updated_at TO img_updated_at';
      COMMIT;
    SQL
    # Reset to default logger
    ActiveRecord::Base.logger = Rails.logger
  end
end
