module Swagger
  module V1
    module Models
      module Apress
        module Images
          class Image < ::Apress::Api::Swagger::Schema
            cattr_accessor :attributes, :simple_attributes, :compute_attributes

            self.simple_attributes = [
              :id,
              :img_file_size,
              :img_file_name,
              :img_content_type
            ]

            self.compute_attributes = [:img]

            self.attributes = simple_attributes + compute_attributes

            swagger_schema name.to_sym do
              key :required, ::Swagger::V1::Models::Apress::Images::Image.attributes

              property :id do
                key :type, :integer
              end

              property :img_file_size do
                key :type, :string
                key :description, 'Size in bytes'
              end

              property :img_file_name do
                key :type, :string
              end

              property :img do
                key :type, :string
                key :description, 'image url'
              end

              property :img_content_type do
                key :type, :string
              end

              property :styles, type: :array do
                items do
                  ::Apress::Images::Image.default_attachment_options[:styles].each_key do |k|
                    key :type, :object
                    property k, type: :object do
                      property :url, type: :string
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
