# coding: utf-8
module Apress
  module Images
    # Public: Добавляет к сущностям возможность иметь картинки
    module ActsAsSubjectable
      extend ActiveSupport::Concern

      module ClassMethods
        # Public: Добавляет субъекту связь с картинками.
        #
        # type    - Symbol, тип необходимой связи: has_one|has_many;
        # name    - Symbol, имя связи;
        # options - Hash, опции связи:
        #           :class_name - Symbol, имя класса с картинками;
        #           :as - Symbol, имя полиморфной связи.
        #
        # Examples
        #
        #    acts_as_subject_of_images :has_one,
        #                              :cover,
        #                              class_name: 'Apress::Deals::OfferCover', as: :subject
        #
        #    # =>
        #
        #      has_one :cover, class_name: 'Apress::Deals::OfferCover', as: :subject
        #
        #      accepts_nested_attributes_for :cover, allow_destroy: true
        #
        #      def cover_with_build
        #         cover_without_build || build_cover()
        #      end
        #      alias_method_chain :cover, :build
        #
        #      def cover_attributes=(attrs)
        #        return unless attrs['id'].present?
        #        new_image = Apress::Deals::OfferCover.find(attrs['id'])
        #        return unless new_image.subject_id.nil? || new_image.subject_id == id
        #
        #        self.cover = new_image
        #        assign_nested_attributes_for_one_to_one_association(:cover, attrs)
        #      end
        #
        # Returns nothing.
        def acts_as_subject_of_images(type, name, options)
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            #{type} :#{name}, #{options}

            accepts_nested_attributes_for :#{name},
                                          allow_destroy: true,
                                          reject_if: ->(attrs) { attrs['id'].blank? }
          RUBY

          return if type != :has_one

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            # Public: Получение уже созданной записи картинки или её инициализация.
            #
            # Returns Image.
            def #{name}_with_build
              #{name}_without_build || build_#{name}(#{options[:conditions]})
            end
            alias_method_chain :#{name}, :build
          RUBY

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            self.send :include, (Module.new do
              extend ActiveSupport::Concern

              included do
                # Public: перезаписывает изображение для субъекта. Если атрибуты валидны, то записи в базе данных
                # обновятся: старое изображение будет отвязано, новое будет привязано к субъекту, а все атрибуты будут
                # сразу же обновлены. Потому что так работает присваивание одиночно ассоциированных моделей. Если есть
                # невалидные атрибуты, то к объекту добавятся ошибки, но перепривязка всё равно произойдёт. Если
                # переданный id указывает на изображение, которое принадлежит другому субъекту, то ничего не произойдёт.
                # Строка
                #
                #   self.#{name} = new_image
                #
                # нужна для того, чтобы мы могли присваивать этим методом изображения, у которых subject_id = nil.
                # Этого нельзя делать через обычную версию этого метода, которую создаёт accepts_nested_attributes_for,
                # из-за ограничений, но нам надо.
                #
                # attrs - Hash. Атрибуты изображения. Ключи могут быть как строками, так и символами.
                #
                # Returns attrs or nil.
                # Raises ActiveRecord::RecordNotFound.
                def #{name}_attributes=(attrs)
                  return unless attrs.with_indifferent_access[:id].present?
                  new_image = #{options.fetch(:class_name)}.find(attrs.with_indifferent_access[:id])
                  return unless new_image.subject_id.nil? || new_image.subject_id == id

                  self.#{name} = new_image
                  assign_nested_attributes_for_one_to_one_association(:#{name}, attrs)
                end
              end
            end)
          RUBY
        end
      end
    end
  end
end
