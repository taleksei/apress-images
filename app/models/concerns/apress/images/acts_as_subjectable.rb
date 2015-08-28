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
        #      def cover_attributes=(attributes)
        #        self.cover = Apress::Deals::OfferCover.find(attributes['id']) \
        #          if attributes['id'].present? && new_record?
        #        assign_nested_attributes_for_one_to_one_association(:cover, attributes)
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
                def #{name}_attributes=(attributes)
                  self.#{name} = #{options[:class_name]}.find(attributes['id']) \\
                    if attributes['id'].present? && new_record?
                  assign_nested_attributes_for_one_to_one_association(:#{name}, attributes)
                end
              end
            end)
          RUBY
        end
      end
    end
  end
end
