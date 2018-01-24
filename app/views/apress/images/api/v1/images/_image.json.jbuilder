json.(image, *::Swagger::V1::Models::Apress::Images::Image.simple_attributes)

json.img path_to_image(image.img)

json.styles do
  json.array! image.img.styles do |name, _|
    json.set! name do
      json.url path_to_image(image.img(name))
    end
  end
end
