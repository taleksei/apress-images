class AddImgUpdatedAtToImages < ActiveRecord::Migration
  def change
    if Rails.env.real_production?
      say <<-TEXT
        ################################################################
        # bundle exec rake images_table:rename_updated_at              #
        ################################################################
      TEXT
    else
      execute 'ALTER TABLE images RENAME COLUMN updated_at TO img_updated_at'

      ::Apress::Images::Image.reset_column_information
    end
  end
end
