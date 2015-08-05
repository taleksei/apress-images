# Apress::Images

[![Dolly](http://dolly.railsc.ru/badges/abak-press/apress-images/master)](http://dolly.railsc.ru/projects/83/builds/latest/?ref=master)

Предоставляет функционал для загрузки и прикрепления изображений

## Installation

### Rails 3.x

Add this lines to your application's Gemfile:

```ruby
gem 'apress-paperclip'
gem 'apress-images'
```

### Rails 4.x

Add this lines to your application's Gemfile:

```ruby
gem 'paperclip', '~> 4.3.0'
gem 'apress-images', '> 2.0'
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
  include Apress::Images::Concerns::Imageable
  
  acts_as_image({
    attachment_options: {
      styles: {thumb: '100x100>'}
    },
    background_processing: false, # допустим, ресайз не хотим делать в фоне,
    max_size: 4, # Максимальный размер изображения ставим в 4 Мб
    watermark_small: 'my_watermark.png' # Своя ватермарка
  })
end

```

## Contributing

1. Fork it ( https://github.com/abak-press/apress-images/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
