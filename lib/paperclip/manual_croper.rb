# coding: utf-8

module Paperclip
  class ManualCroper < Thumbnail
    def transformation_command
      crop_command + super.reject { |t| t =~ /-crop/ }
    end

    private

    def crop_command
      target = @attachment.instance

      crop_w = Integer(target.crop_w)
      crop_h = Integer(target.crop_h)
      crop_x = Integer(target.crop_x)
      crop_y = Integer(target.crop_y)

      ["-crop #{crop_w}x#{crop_h}+#{crop_x}+#{crop_y}", "+repage"]
    end
  end
end
