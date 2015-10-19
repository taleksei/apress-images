# coding: utf-8

class CreateApressImages < ActiveRecord::Migration
  def self.up
    unless table_exists? :images
      create_table :images do |t|
        t.references :subject, polymorphic: true
        t.integer :position, null: false, default: 0
        t.string :img_file_name
        t.string :img_content_type
        t.integer :img_file_size
        t.timestamps
        t.string :title
        t.text :comment
      end
    end

    unless column_exists?(:images, :processing)
      add_column :images, :processing, :boolean

      say 'Set default processing column...'

      Apress::Images::Image.where(processing: nil).find_in_batches(batch_size: 2_000) do |batch|
        Apress::Images::Image.update_all({processing: false}, {id: batch.map(&:id)})
      end

      say 'Alter processing column...'

      change_column :images, :processing, :boolean, null: false, default: false

      Apress::Images::Image.reset_column_information
    end

    unless column_exists?(:images, :node)
      add_column :images, :node, :integer

      say 'Set default node column...'

      Apress::Images::Image.where(node: nil).find_in_batches(batch_size: 2_000) do |batch|
        Apress::Images::Image.update_all({node: 0}, {id: batch.map(&:id)})
      end

      say 'Alter node column...'

      change_column :images, :node, :integer, null: false, default: 0

      Apress::Images::Image.reset_column_information
    end

    say 'Upgrade indexes...'
    say 'Normalize images positions before index creation...'

    sub_query = Apress::Images::Image.
      group(:subject_id, :subject_type).
      select('MIN(id) AS id, subject_id, subject_type').
      to_sql

    Apress::Images::Image.
      from("(#{sub_query}) AS #{Apress::Images::Image.quoted_table_name}").
      find_each(batch_size: 2_000) do |image|
      Apress::Images::Image.normalize_positions(image.subject_id, image.subject_type)
    end

    execute 'END;'

    say 'Create index...'

    execute <<-SQL.strip_heredoc
      CREATE UNIQUE INDEX CONCURRENTLY "idx_images_on_subject_position"
        ON "images" (subject_type, subject_id, "position");
    SQL

    say 'Set constraints...'

    execute <<-SQL.strip_heredoc
      ALTER TABLE "images" ADD CONSTRAINT "images_subject_position"
        UNIQUE USING INDEX "idx_images_on_subject_position" DEFERRABLE INITIALLY DEFERRED;
    SQL

    say 'Drop old index...'

    if index_exists?(:images, [:subject_type, :subject_id])
      execute <<-SQL.strip_heredoc
        DROP INDEX CONCURRENTLY #{index_name(:images, [:subject_type, :subject_id])};
      SQL
    end
  end

  def self.down
    drop_table :images
  end
end
