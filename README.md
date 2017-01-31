# Apress::Images

[![Build Status](https://drone.railsc.ru/api/badges/abak-press/apress-images/status.svg)](https://drone.railsc.ru/abak-press/apress-images)

Предоставляет функционал для загрузки и прикрепления изображений

## Requirements

paperclip >= v4.x.x

## Installation

Add this lines to your application's Gemfile:

```ruby
gem 'paperclip', '~> 4.2'
gem 'apress-images', git: 'git@github.com:abak-press/apress-images.git', branch: 'paperclip-upgrade'
```

And then execute:

    $ bundle

Or install it yourself as:

```bash
    $ gem install paperclip
    $ gem install apress-images
```

## Usage

```ruby

class Avatar < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(
    attachment_options: {
      styles: {thumb: '100x100>'}
    },
    max_size: 4, # Максимальный размер изображения ставим в 4 Мб (по-умолчанию 15 Мб)
    watermark_small: 'my_watermark.png', # Своя ватермарка
    background_processing: true # допустим, хотим, чтобы ресайз происходил в фоне
  )
end

```

### Указываем таблицу (по-умолчанию 'images')

```ruby

class Dummy < ActiveRecord::Base
  acts_as_image(table_name: 'dummies')
end
```

### Фоновая обработка изображений

```ruby

class Avatar < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(
    background_processing: true,
    processing_image_url: '/images/:style/processing.jpg' # выставить свою заглушку изображения на время ресайза
  )
end

@avatar = Avatar.new(img: File.new(...))
@avatar.save
@avatar.img.url # => /images/original/processing.png
@avatar.img.url(:thumb) # => /images/thumb/processing.png

# После ресайза в фоне

@avatar.reload
@avatar.img.url #=> "/system/images/3/original/IMG_2772.JPG?1267562148"

```

### Кадрирование изображений

```ruby
class Avatar < ActiveRecord::Base
  include Apress::Images::Imageable

  acts_as_image(
    attachment_options: {
      styles: {
        thumb: {
          geometry: '100x100>'
        }
      }
    },
    # хотим кадрировать данный стиль
    cropable_style: :thumb,
    cropable_style_options: {min_height: 100, min_width: 100}
  )
end

# Кадрирование происходит только в случае если переданы все crop_ аттрибуты
@avatar = Avatar.new(crop_x: 400, crop_y: 400, crop_h: 100, crop_w: 100)
@avatar.img = File.new(...)
@avatar.save

file = Paperclip.io_adapters.for(@avatar.img.styles[:thumb])
Paperclip::Geometry.from_file(file).to_s #=> '100x100'
```


## Contributing

1. Fork it ( https://github.com/abak-press/apress-images/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
