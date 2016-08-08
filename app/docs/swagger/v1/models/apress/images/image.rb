module Swagger
  module V1
    module Models
      module Apress
        module Images
          class Image < ::Apress::Api::Swagger::Schema
            cattr_accessor :attributes
            self.attributes = [
              :id,
              :img_file_size,
              :img_file_name,
              :img,
              :img_content_type
            ]

            swagger_schema name.to_sym do
              key :required, ::Swagger::V1::Models::Apress::Images::Image.attributes

              property :id do
                key :type, :integer
              end

              property :content_type do
                key :type, :string
              end

              property :url do
                key :type, :string
              end

              property :file_size do
                key :type, :string
                key :description, 'Size in bytes'
              end
            end
          end
        end
      end
    end
  end
end
