# coding: utf-8
require 'paperclip/url_generator'

module Apress
  module Images
    # Public: расширенный класс генератора url для обрабатываемых в фоне картинок
    class UrlGenerator < ::Paperclip::UrlGenerator
      attr_reader :attachment, :attachment_options

      def for(style_name, options)
        interpolated_url = attachment_options[:interpolator].interpolate(most_appropriate_url, attachment, style_name)
        escaped_url = escape_url_as_needed(interpolated_url, options)

        timestamp_as_needed(escaped_url, options)
      end

      # Public: наиболее подходящий url к картинке
      #
      # если картинка в обработке и предоставлен путь к заглушке, вернет Url до заглушки
      # иначе вернет url по-умолчанию
      #
      # Returns String
      def most_appropriate_url
        return super unless attachment.processing?
        return attachment_options[:url] if attachment.original_filename.present? && !delayed_default_url?

        if attachment.delayed_options && attachment.processing_image_url && attachment.processing?
          return attachment.processing_image_url
        end

        default_url
      end

      def timestamp_possible?
        delayed_default_url? ? false : super
      end

      def delayed_default_url?
        !attachment.job_is_processing && !attachment.dirty? &&
          attachment.delayed_options.try(:[], :processing_image_url) &&
          attachment.processing?
      end
    end
  end
end
