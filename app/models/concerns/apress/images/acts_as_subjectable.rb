# coding: utf-8
module Apress
  module Images
    # Public: Добавляет к сущностям возможность иметь картинки
    module ActsAsSubjectable
      extend ActiveSupport::Concern

      module ClassMethods
        # Public: Добавляет субъекту связь с картинками.
        #
        # options - Hash, параметры акта, по умолчанию {as: :subject}:
        #           :association_type  - Symbol, тип необходимой связи: has_one|has_many;
        #           :association_class - Class, класс объекта картинок;
        #           :association_name  - Symbol, имя связи;
        #           :polymorphic_name  - Symbol, имя полиморфной связи, по умолчанию :subject.
        #
        # Examples
        #
        #    acts_as_subject_of_images(
        #      association_type: :has_one,
        #      association_name: :cover,
        #      association_class: Apress::Deals::OfferCover
        #    )
        #
        #    # =>
        #
        #      has_one :cover, class_name: 'Apress::Deals::Cover', as: :subject
        #
        #      accepts_nested_attributes_for :cover, allow_destroy: true
        #
        #      def cover_with_build
        #         cover_without_build || build_cover
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
        def acts_as_image_subjectable(options)
          define_singleton_method(:association_type) { options.fetch :association_type }
          define_singleton_method(:association_class) { options.fetch :association_class }
          define_singleton_method(:association_name) { options.fetch :association_name }
          define_singleton_method(:polymorphic_name) { options.fetch :polymorphic_name, :subject }

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            #{association_type} :#{association_name}, class_name: '#{association_class}', as: :#{polymorphic_name}

            accepts_nested_attributes_for :#{association_name},
                                          allow_destroy: true,
                                          reject_if: ->(attrs) { attrs['id'].blank? }

            # Public: Получение уже созданной записи картинки или её инициализация.
            #
            # Returns Image.
            def #{association_name}_with_build
              #{association_name}_without_build || build_#{association_name}
            end
            alias_method_chain :#{association_name}, :build
          RUBY

          return if association_type != :has_one

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            self.send :include, (Module.new do
              extend ActiveSupport::Concern

              included do
                def #{association_name}_attributes=(attributes)
                  self.#{association_name} = #{association_class}.find(attributes['id']) \\
                    if attributes['id'].present? && new_record?
                  assign_nested_attributes_for_one_to_one_association(:#{association_name}, attributes)
                end
              end
            end)
          RUBY
        end
      end
    end
  end
end
