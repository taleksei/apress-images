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
    background_processing: true, # допустим, хотим, чтобы ресайз происходил в фоне
    # Если установлено, то размеры исходного изображения будут
    # сохранены в виртуальном аттрибуте avatar.source_image_geometry (по-умолчанию false)
    need_extract_source_image_geometry: true
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
        big: {
          geometry: '200x200>'
        },
        thumb: {
          geometry: '50x50>'
        }
      }
    },
    # хотим кадрировать данные стили
    cropable_styles: [:big, :thumb],
    crop_options: {min_height: 100, min_width: 100}
  )
end

# Кадрирование происходит только в случае если переданы все crop_ аттрибуты
@avatar = Avatar.new(crop_w: 100, crop_h: 50, crop_x: 400, crop_y: 400)
@avatar.img = File.new(...)
@avatar.save

big_file = Paperclip.io_adapters.for(@avatar.img.styles[:big])
Paperclip::Geometry.from_file(big_file).to_s #=> '100x50'
thumb_file = Paperclip.io_adapters.for(@avatar.img.styles[:thumb])
# если кадрируемая область больше размеров стиля, то после обрезки она будет уменьшена
Paperclip::Geometry.from_file(thumb_file).to_s #=> '50x25'
```

### Хранение файлов только уникальных картинок

```ruby
class Avatar < ActiveRecord::Base
  include Apress::Images::Imageable

  # deduplication - флаг для включения дедупликации
  # deduplication_additional_attributes - список колонок, которые необходимо копировать в дубли
  # deduplication_moved_attributes - список колонок, которые копируются из дубля, при попытке удаления оригинала
  acts_as_image(
    attachment_options: {styles: {big: {geometry: '200x200>'}}},
    deduplication: true,
    deduplication_additional_attributes: %w(node processing),
    deduplication_moved_attributes: %w(subject_id subject_field)
  )
end
```
Для корректной работы дедупликации необходимы следующие колонки:
1) fingerprint - цифровой отпечаток загруженной пользователем картинки
2) img_fingerprint - цифровой отпечаток нарезаного стиля original
3) fingerprint_parent_id - id записи, дублем для которой является текущая

Необходимо создать foreign key на колонку fingerprint_parent_id (ON DELETE RESTRICT).
Так же рекомендуется добавить триггер использующий функцию image_update_img_from_parent,
для корректного сохранения дубликатов при параллельной нарезке оригинала.

## Contributing

1. Fork it ( https://github.com/abak-press/apress-images/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
