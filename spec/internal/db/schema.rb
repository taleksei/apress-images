ActiveRecord::Schema.define do
  create_table(:subjects, force: true)

  create_table :delayed_images, force: true do |t|
    t.references :subject, polymorphic: true
    t.string :img_file_name
    t.string :img_content_type
    t.integer :img_file_size
    t.integer :position, null: false, default: 0
    t.boolean :processing, null: false, default: false
    t.timestamp :created_at
    t.timestamp :img_updated_at
  end

  create_table :disordered_images, force: true do |t|
    t.references :subject, polymorphic: true
    t.string :img_file_name
    t.string :img_content_type
    t.integer :img_file_size
  end

  create_table :custom_attribute_images, force: true do |t|
    t.references :subject, polymorphic: true
    t.string :custom_file_name
    t.string :custom_content_type
    t.integer :custom_file_size
  end

  create_table :duplicated_images, force: true do |t|
    t.references :subject, polymorphic: true
    t.string :img_file_name
    t.string :img_content_type
    t.string :fingerprint
    t.string :img_fingerprint
    t.integer :fingerprint_parent_id
    t.integer :img_file_size
    t.integer :position, null: false, default: 0
    t.integer :node, null: false, default: 0
    t.boolean :processing, null: false, default: false
    t.timestamp :created_at
    t.timestamp :img_updated_at
  end

  execute File.read(::Apress::Images::Engine.root.join('db/schema/public/image_update_img_from_parent.sql'))

  execute <<-SQL
    CREATE TRIGGER tr_duplicated_images_update_processing
    BEFORE INSERT OR UPDATE OF fingerprint_parent_id
    ON duplicated_images
    FOR EACH ROW
    WHEN (NEW.fingerprint_parent_id IS NOT NULL AND NEW.processing)
    EXECUTE PROCEDURE image_update_img_from_parent();
  SQL
end
