# coding: utf-8

namespace :images_table do
  task :upgrade => :environment do

    connection = ActiveRecord::Base.connection

    if connection.column_exists?(:images, :processing)
      puts 'Set default processing field...'

      Apress::Images::Image.where(processing: nil).find_in_batches(batch_size: 2000) do |batch|
        Apress::Images::Image.update_all({processing: false}, {id: batch.map(&:id)})
      end

      puts 'Alter processing column...'

      connection.execute <<-SQL.strip_heredoc
        ALTER TABLE "images" ALTER COLUMN "processing" SET DEFAULT false;
        ALTER TABLE "images" ALTER COLUMN "processing" SET NOT NULL;
      SQL
    end

    if connection.column_exists?(:images, :node)
      puts 'Set default node field...'

      Apress::Images::Image.where(node: nil).find_in_batches(batch_size: 2000) do |batch|
        Apress::Images::Image.update_all({node: 0}, {id: batch.map(&:id)})
      end

      puts 'Alter node column...'

      connection.execute <<-SQL.strip_heredoc
        ALTER TABLE "images" ALTER COLUMN "node" SET DEFAULT 0;
        ALTER TABLE "images" ALTER COLUMN "node" SET NOT NULL;
      SQL
    end

    if connection.index_exists?(:subject_type, :subject_id)
      puts 'Upgrade indexes...'

      connection.execute 'END;'

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

      connection.execute 'END;'

      connection.execute <<-SQL.strip_heredoc
        DROP INDEX CONCURRENTLY #{connection.index_name(:images, [:subject_type, :subject_id])};
      SQL
    end
  end
end
