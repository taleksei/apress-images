class AddImgUpdatedAtToImages < ActiveRecord::Migration
  def change
    add_column :images, :img_updated_at, :timestamp

    return if Rails.env.test?

    if Rails.env.real_production?
      say <<-TEXT
        ################################################################
        # bundle exec rake migrations:images:fill_img_updated_at #
        ################################################################
      TEXT
    else
      Rake::Task['migrations:images:fill_img_updated_at'].invoke
    end
  end
end
