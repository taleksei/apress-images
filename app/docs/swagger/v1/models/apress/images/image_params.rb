module Swagger
  module V1
    module Models
      module Apress
        module Images
          class ImageParams < ::Apress::Api::Swagger::Schema
            cattr_accessor :attributes, :attributes_types

            self.attributes_types = {
              id: 'integer',
              img: 'file',
              :_destroy => 'boolean'
            }

            self.attributes = attributes_types.keys

            swagger_schema name.to_sym do
              key :required, ::Swagger::V1::Models::Apress::Images::ImageParams.attributes

              property :id do
                key :type, :integer
                key :description, 'Used for updating existing records'
              end

              property :img do
                key :type, :string
              end

              property :_destroy do
                key :type, :boolean
              end
            end
          end
        end
      end
    end
  end
end
