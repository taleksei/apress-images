# coding: utf-8

module Paperclip
  class ManualCroper < Thumbnail
    def transformation_command
      crop_command + super.reject { |t| t =~ /-crop/ }
    end

    private

    def crop_command
      model = @attachment.instance
      reduction_scale = image_reduction_scale(@attachment, model)

      crop_w = (Integer(model.crop_w) * reduction_scale).round
      crop_h = (Integer(model.crop_h) * reduction_scale).round
      crop_x = (Integer(model.crop_x) * reduction_scale).round
      crop_y = (Integer(model.crop_y) * reduction_scale).round

      ["-crop #{crop_w}x#{crop_h}+#{crop_x}+#{crop_y}", "+repage"]
    end

    # Internal: Коэффициент уменьшения исходного размера до размеров original стиля.
    #
    # attachment - Paperclip::Attachment.
    # model - subclass of ActiveRecord::Base.
    #
    # Returns Rational.
    def image_reduction_scale(attachment, model)
      source_image_geometry = model.source_image_geometry
      original_style_geometry = attachment.styles[:original].geometry
      reduced_geometry = source_image_geometry.resize_to(original_style_geometry)

      Rational(reduced_geometry.width, source_image_geometry.width)
    end
  end
end
