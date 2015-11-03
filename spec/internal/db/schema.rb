ActiveRecord::Schema.define do
  create_table(:subjects, force: true)

  create_table :delayed_images, force: true do |t|
    t.string :img_file_name
    t.string :img_content_type
    t.integer :img_file_size
    t.integer :position, null: false, default: 0
    t.boolean :processing, null: false, default: false
  end
end
