# coding: utf-8

module Apress
  module Images
    # Public: Сервис загрузки картинок
    #
    # Example
    #   service = Apress::Images::UploadService.new(
    #     'Avatar',
    #     subject_type: 'User',
    #     subject_id:   1
    #   )
    #   image_from_file = service.upload(File.open(...))
    #   image_from_url  = service.upload('http://example.com/image.jpg')
    class UploadService
      attr_reader :model, :image_attributes, :image_crop_attributes

      # Public: конструктор
      #
      # imageable_model - String, название модели
      # params - Hash (default: {})
      #          :subject_type - String тип объекта, которому добавляются изображения
      #          :subject_id   - String иденитфикатор объекта, которому добавляются изображения
      #          :id           - String|Integer идентификатор изображения
      #
      # Returns ImageUploadService instance
      def initialize(imageable_model, params = {})
        @model = image_model(imageable_model)
        @image_crop_attributes = params.slice(*Cropable::CROP_ATTRS)
        @image_attributes = extract_image_attrs(params)
      end

      # Public: Создание изображения
      #
      # source   - IO or String источник изображения (может быть урлом)
      # position - Integer (default: следующая за последней позиция)
      #
      # Raises ActiveRecord::RecordInvalid
      #
      # Returns Object изображение
      def upload(source, position = current_position.next)
        source_attribute = source.is_a?(String) ? :img_url : :img
        attributes = {source_attribute => source, position: position}.merge!(image_attributes)

        image = if attributes[:id].present?
                  model.find(attributes[:id])
                else
                  model.new
                end

        image.assign_attributes(image_crop_attributes)
        image.assign_attributes(attributes)
        image.save!
        image
      end

      class << self
        # Public: Проверка состояния отложенной обработки
        #
        # params - Hash
        #          :model - String, модель с изображением
        #          :id - Integer, идентификатор изображения
        #
        # Returns Boolean
        def in_process?(params)
          image = image_model(params.fetch(:model)).find(params.fetch(:id))
          image.respond_to?(:processing?) && image.processing?
        end

        def image_model(model_name)
          model_name = model_name.classify
          raise ArgumentError, 'Model name is not allowed' if allowed_models.exclude? model_name
          model_name.constantize
        end

        def allowed_models
          ::Rails.application.config.imageable_models.map(&:classify)
        end
      end

      protected

      delegate :image_model, to: 'self.class'

      def allowed_subjects
        @allowed_subjects ||= ::Rails.application.config.imageable_subjects.map(&:classify)
      end

      # Internal: Текущая последняя позиция
      #
      # Returns Integer
      def current_position
        @current_position ||= image_attributes.present? && model.where(image_attributes).maximum(:position) || 0
      end

      # Internal: Атрибуты изображения, для указанного в параметрах объекта
      # Note: Объект может быть не указан
      #
      # params - Hash (по умолчанию {}):
      #          :subject_type - String тип объекта, которому добавляются изображения
      #          :subject_id   - String иденитфикатор объекта, которому добавляются изображения
      #          :id           - String|Integer идентификатор изображения
      #
      # Returns Hash, атрибуты изображения.
      def extract_image_attrs(params = {})
        attributes = {}
        attributes[:id] = params[:id].to_i if params[:id].present?
        return attributes if params[:subject_type].blank?

        subject_type = params[:subject_type].camelize
        raise ArgumentError, 'Subject is not allowed' if allowed_subjects.exclude? subject_type

        attributes[:subject_type] = subject_type.constantize.model_name
        attributes[:subject_id] = params[:subject_id].to_i if params[:subject_id].present?
        attributes
      end
    end
  end
end
