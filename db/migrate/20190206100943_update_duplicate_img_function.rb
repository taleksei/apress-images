class UpdateDuplicateImgFunction < ActiveRecord::Migration
  def change
    execute File.read(::Apress::Images::Engine.root.join('db/schema/public/image_update_img_from_parent.sql'))
  end
end
